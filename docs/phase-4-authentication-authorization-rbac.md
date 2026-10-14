# PHASE 4: AUTHENTICATION, AUTHORIZATION & USER SESSIONS
## Hospital Management System (HMS) Modernization: Dual-Token JWT & Granular RBAC

---

## 1. Phase Objective & Overview
The objective of **Phase 4** is to replace the fragile, cookie-dependent legacy PHP session system with an enterprise-grade, stateless **Dual-Token JWT (JSON Web Token)** architecture with **Argon2id** password hashing and **Granular Role-Based Access Control (RBAC)** spanning both backend (**NestJS**) and frontend (**Flutter Web & Android**).

At the completion of Phase 4:
1. **Live Supabase PostgreSQL** synchronizes the newly provisioned `refresh_tokens` model with full foreign-key constraints and token rotation tracking.
2. **NestJS `AuthModule`** provides secure authentication, issuance of short-lived Access Tokens (15 min) and long-lived Refresh Tokens (7 days), token family rotation to mitigate replay attacks, and current profile resolution (`/auth/me`).
3. **NestJS `PermissionsModule`** and `@RequirePermissions()` guard enforce 11 granular healthcare access keys, allowing fine-grained privilege assignment with Super Admin administrative override.
4. **Flutter Client (`apps/frontend`)** features a high-fidelity clinical `LoginScreen` with 1-click test role access, an interactive `PermissionsManagerScreen`, reactive Riverpod state management (`authProvider`), persistent token storage (`AuthStorage`), and automatic token refreshing on HTTP 401 via `ApiClient`.
5. **All updates operate directly against the live online Supabase PostgreSQL database and production Railway backend architecture.**

---

## 2. Legacy State Analysis: What Was Done (Current State)
In the legacy PHP + MySQL application:
- **Authentication**: Managed through Apache `$_SESSION` cookies set in [`auth.php`](file:///c:/DATA/Stuff/Project/SEM-9/auth.php) and [`login.php`](file:///c:/DATA/Stuff/Project/SEM-9/login.php). Mobile Android apps could not reliably maintain cross-origin cookies.
- **Password Storage**: The `staff` table explicitly maintained a column `plain_password VARCHAR(100)` storing default passwords like `staff123` in plain cleartext.
- **Credential Exposure**: Any receptionist or staff user could inspect network payloads and read raw passwords in cleartext via `api/permissions.php`.
- **Token Security**: No stateless tokens, no cryptographic signing, and no expiry revocation. If a session cookie was hijacked, there was no way to revoke it without clearing the entire server session directory.
- **Permission Checking**: Checked procedurally on each PHP page using `checkStaffPermission(...)`, with inconsistent fallback queries that leaked multi-tenant records (`WHERE hospital_id = ? OR hospital_id IS NULL`).

---

## 3. Gaps & What Needs to Be Improved
1. **Critical Password Insecurity**:
   - Plaintext passwords stored directly in database columns violated basic healthcare data compliance standards (HIPAA, ABDM, DPDPA 2023).
2. **Session Desynchronization**:
   - Web browsers dropping Wi-Fi connection or Android tablets switching between cell towers and hospital Wi-Fi lost session state, forcing staff to re-authenticate constantly.
3. **No Granular Endpoint Guards**:
   - Many legacy endpoints lacked explicit server-side permission checks, relying solely on whether a button was hidden in the HTML template.
4. **Missing Token Rotation & Replay Defense**:
   - Legacy system had zero mechanisms to detect or prevent credential replays.

---

## 4. How We Make It Good (Core Architecture & Execution)

### A. Dual-Token JWT Strategy with Family Rotation
- **Access Token (15-Minute Expiry)**:
  - Cryptographically signed using `JWT_ACCESS_SECRET`.
  - Injected as `Authorization: Bearer <token>` on every API call.
  - Payload contains:
    ```json
    {
      "sub": 1,
      "username": "admin",
      "hospitalId": 1,
      "role": "Super Admin",
      "permissions": ["dashboard", "patients", "appointments", "queue", "doctors", "staff", "attendance", "bed", "medical_files", "bhooma_ai", "settings"],
      "iat": 1728893400,
      "exp": 1728894300
    }
    ```
- **Refresh Token (7-Day Expiry)**:
  - Cryptographically signed using `JWT_REFRESH_SECRET`.
  - Persisted in the live Supabase PostgreSQL `refresh_tokens` table.
  - On `/auth/refresh`, the presented token is verified and immediately marked `is_revoked = true` while a new token pair is issued (Token Family Rotation).
  - If an already-revoked refresh token is re-submitted, the backend detects a potential token theft and revokes all active refresh tokens for that staff member.

### B. Argon2id Password Hashing
- Replaces legacy plaintext passwords with **Argon2id** (the state-of-the-art password hashing standard recommended by OWASP).
- Passwords verified in constant time preventing timing side-channel attacks.

### C. NestJS Authorization Guards & Decorators
- `@Public()`: Explicitly whitelists public routes (`/auth/login`, `/auth/refresh`, `/auth/register-hospital`, `/health`).
- `@CurrentUser()`: Automatically injects the parsed, validated staff profile into controller parameters.
- `@RequirePermissions('patients', 'appointments')`: Declares required permission keys on specific endpoints.
- `PermissionsGuard`: Compares endpoint requirements against the user's active permissions. Automatically grants Super Admin bypass.

### D. The 11 Granular Clinical Permissions Matrix
| Key | Clinical Scope | Target Modules |
|---|---|---|
| `dashboard` | Executive KPI analytics & live bed occupancy | Dashboard Screen |
| `patients` | Patient directory, demographics & QR lookups | Patients Directory |
| `appointments` | Doctor schedule booking & collision guard | Appointments Screen |
| `queue` | Live token progression & 4-step consultation | Queue Pipeline Screen |
| `doctors` | Practitioner directory & duty hour management | Doctors Screen |
| `staff` | Staff directory, account status & RBAC switches | Staff & Permissions Screen |
| `attendance` | Daily check-in, geofencing & selfie verification | Attendance Screen |
| `bed` | Inpatient bed management, ICU & ward occupancy | Beds & Wards Screen |
| `medical_files` | Private S3 file uploads, scans & download audit | Medical Gallery Screen |
| `bhooma_ai` | BHOOMA AI conversational assistant & tool calls | BHOOMA AI Screen |
| `settings` | Hospital tenancy configuration & API diagnostics | Settings Screen |

---

## 5. What Makes It Great (Enterprise & Healthcare Polish)

1. **Direct Online Supabase Synchronization**:
   - `refresh_tokens` model was pushed directly to the live Supabase cloud database (`aws-0-ap-southeast-2.pooler.supabase.com:5432`) with zero local drift.
2. **Railway Production Alignment**:
   - Both `railway.json` and `Dockerfile` are configured with `npx prisma db push --skip-generate && node dist/main.js` for safe, automated zero-downtime container deployments on Railway.
3. **1-Click Clinical Quick Login Chips**:
   - The Flutter `LoginScreen` includes 1-click test chips for:
     - **Super Admin** (`admin` / `Admin@1234` — All 11 permissions)
     - **Doctor** (`dr.rajesh` / `Doctor@1234` — Clinical & BHOOMA AI)
     - **Receptionist** (`reception` / `Staff@1234` — Front desk queue & appointments)
     - **Nurse** (`nurse.sunita` / `Staff@1234` — ICU bed management & medical files)
4. **Silent HTTP 401 Auto-Recovery**:
   - `ApiClient` catches `401 Unauthorized` responses in the background, executes `/auth/refresh` transparently, updates the stored token, and retries the original request without disrupting the doctor's active clinical entry.
5. **Dynamic UI Adaptation**:
   - The sidebar and mobile drawer filter navigation options dynamically based on the logged-in staff member's permissions, preventing unauthorized access before a request even leaves the device.

---

## 6. Backend API Inventory (Authentication & Permissions)

| Method | Endpoint | Access Level | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/login` | Public | Authenticates credentials via Argon2id; issues 15m Access Token + 7d Refresh Token |
| `POST` | `/api/v1/auth/refresh` | Public | Exchanges valid refresh token for rotated token pair |
| `POST` | `/api/v1/auth/logout` | Authenticated | Revokes active refresh token in PostgreSQL |
| `GET` | `/api/v1/auth/me` | Authenticated | Resolves current staff profile, hospital metadata, and active permissions |
| `POST` | `/api/v1/auth/register-hospital` | Public | Provisions new hospital tenant with Super Admin user |
| `GET` | `/api/v1/permissions/presets` | Authenticated | Returns clinical role presets (Doctor, Nurse, Receptionist, Admin) |
| `GET` | `/api/v1/permissions/:staffId` | `staff` / Admin | Retrieves full 11-permission matrix for a staff member |
| `PUT` | `/api/v1/permissions/:staffId` | `staff` / Admin | Updates active permission flags and account status |

---

## 7. Verification & Test Evidence

### A. Live Supabase PostgreSQL Verification
- Executed direct query on `refresh_tokens` table in live cloud database:
  ```text
  Datasource: aws-0-ap-southeast-2.pooler.supabase.com:5432
  Result: Refresh token table in Supabase works! Count: 3
  ```

### B. Live Endpoint Tests
1. **Admin Login (`POST /api/v1/auth/login`)**:
   - Status: `200 OK`
   - User: `admin` | Role: `Super Admin` | Permissions: 11 active
2. **Current Profile (`GET /api/v1/auth/me`)**:
   - Status: `200 OK`
   - Profile: `Hospital Administrator` (MEDICARE-01)
3. **Token Refresh with Rotation (`POST /api/v1/auth/refresh`)**:
   - Status: `200 OK`
   - New rotated access token and refresh token successfully issued.
4. **Role Presets (`GET /api/v1/permissions/presets`)**:
   - Status: `200 OK`
   - Presets returned: `['Super Admin', 'Doctor', 'Receptionist', 'Nurse']`
5. **Doctor Login (`POST /api/v1/auth/login`)**:
   - Status: `200 OK`
   - User: `dr.rajesh` (Doctor, Cardiology)
6. **Permission Guard Enforcement (`GET /api/v1/permissions/1`)**:
   - Status: `403 Forbidden` when queried with doctor token (Doctor lacks `staff` administrative permission).

---

## 8. Phase 4 Definition of Done (DoD)
- [x] `RefreshToken` model created and synchronized to live Supabase PostgreSQL.
- [x] Argon2id password hashing implemented and verified.
- [x] Dual-token JWT architecture (15m access / 7d refresh) with family rotation implemented.
- [x] Permissions guard enforcing all 11 granular healthcare permission keys.
- [x] NestJS build compiles with 0 errors (`npm run build`).
- [x] Flutter `LoginScreen` built with Material 3 clinical design and quick-test accounts.
- [x] Flutter `PermissionsManagerScreen` built with role preset triggers.
- [x] `AdaptiveShell` updated with real user initials, role badges, and permission-filtered navigation.
- [x] `AppRouter` updated with route redirect guards and `refreshListenable`.
- [x] Railway container configs (`railway.json`, `Dockerfile`) synchronized for live deployment.

---

**Phase 4 Status**: **COMPLETE & VERIFIED**
**Next Phase**: Proceed to **Phase 5 — Core Clinical Workflows** (Patient Registration with duplicate guard, Appointment Scheduling with doctor slot anti-collision, Live Token Queue pipeline, and 4-Step Clinical Workstation).
