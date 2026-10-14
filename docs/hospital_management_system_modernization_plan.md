# MASTER MODERNIZATION & ARCHITECTURE PLAN
## Hospital Management System (HMS): PHP + MySQL to Flutter + NestJS + PostgreSQL

---

# SECTION 1: EXECUTIVE SUMMARY

### 1.1 Project Mission & Context
This architectural engineering document defines the complete modernization roadmap for the **Hospital Management System (HMS)**. The current application is a monolithic web system built with **PHP 8.0+**, **MySQL / MariaDB**, **Tailwind CSS 3.x (via CDN)**, vanilla ES6 JavaScript, and an experimental on-premise AI clinical assistant (**BHOOMA AI**) interfaced with a local **Ollama** server.

The target system is a unified, cross-platform healthcare operational platform designed for:
- **Hospital Workstations & Desktop Web**: **Flutter Web** compiled with WebAssembly (Wasm) and CanvasKit/HTML rendering, deployed as a secure Single Page Application (SPA).
- **Mobile & Tablet Devices**: **Flutter Android** generating signed, hardened release APKs for handheld hospital rounds, nursing triage, doctor rounds, and bedside QR scanning.
- **Backend API Boundary**: **NestJS (TypeScript)** modular enterprise service orchestrating validation, business transactions, RBAC/fine-grained permissions, audit logging, and external integrations.
- **Data Persistence**: **PostgreSQL** hosted via **Supabase** (utilizing PostgreSQL 15+, strict Foreign Key constraints, Row-Level Security (RLS) enforcement, and connection pooling).
- **Medical File Storage**: Migration from inline database `LONGBLOB` fields to private **Supabase Object Storage** buckets with cryptographic pre-signed URLs and zero public access.

### 1.2 Target Hospital Profile & Operational Constraints
- **Target Institution**: Small-to-medium clinical hospital (20–30 Doctors, 1,000–5,000 active patient profiles, 50–100 daily OPD/IPD visits, 40+ inpatient beds).
- **Physical Server Policy**: The hospital operates **without a dedicated on-premise physical server** and has explicitly declined on-site server hardware acquisition due to capital expenditure (CapEx) and operational maintenance costs.
- **Access Scope**: Hybrid access model—workstation terminals operate inside the hospital local network, while doctors and administrators require secure remote access outside hospital walls.
- **Data Residency & Privacy**: The system handles sensitive clinical information (Protected Health Information - PHI). Development, staging, and demo environments will run strictly on synthetic test datasets. Cloud regions are evaluated with respect to the Indian **Digital Personal Data Protection Act (DPDPA 2023)** and Ayushman Bharat Digital Mission (ABDM) standards.

### 1.3 Modernization Roadmap Execution Status Tracker

| Phase | Milestone Name | Scope | Verification Status | Artifact Documentation |
|---|---|---|:---:|---|
| **Phase 1** | Architecture, Monorepo & Supabase Setup | Monorepo layout, toolchains, cloud environment config | ✅ **COMPLETED** | [`phase-1-architecture-decisions.md`](file:///c:/DATA/Stuff/Project/SEM-9/docs/phase-1-architecture-decisions.md) |
| **Phase 2** | Database Schema & Core Backend Scaffolding | Prisma models, Supabase push, NestJS modules & health check | ✅ **COMPLETED** | [`phase-2-database-backend-core.md`](file:///c:/DATA/Stuff/Project/SEM-9/docs/phase-2-database-backend-core.md) |
| **Phase 3** | Flutter Shell & Material 3 Design System | Responsive desktop/mobile shell, clinical color tokens, router | ✅ **COMPLETED** | [`phase-3-flutter-shell-design-system.md`](file:///c:/DATA/Stuff/Project/SEM-9/docs/phase-3-flutter-shell-design-system.md) |
| **Phase 4** | Authentication, Authorization & RBAC | Dual-token JWT, Argon2id, 11-key RBAC, Supabase RLS policies | ✅ **COMPLETED** | [`phase-4-authentication-authorization-rbac.md`](file:///c:/DATA/Stuff/Project/SEM-9/docs/phase-4-authentication-authorization-rbac.md) |
| **Phase 5** | Core Clinical Workflows (OPD / IPD / Rx) | Patients, slot collision, live triage queue, 4-step workstation | ✅ **COMPLETED** | [`phase-5-core-clinical-workflows.md`](file:///c:/DATA/Stuff/Project/SEM-9/docs/phase-5-core-clinical-workflows.md) |
| **Phase 6** | Medical File Storage & Gallery Viewer | Private Supabase Storage bucket, signed URLs, file audit | ⏳ **READY FOR NEXT** | `phase-6-medical-files-storage.md` |
| **Phase 7** | Bed Management, Staff Attendance & Geofence | Interactive bed map, geofence Haversine, daily roster | ⏸️ Queued | `phase-7-beds-attendance.md` |
| **Phase 8** | QR System, Vector PDF & BHOOMA AI | Biometric QR cards, PDF printing, human-in-loop AI chat | ⏸️ Queued | `phase-8-qr-reports-bhooma-ai.md` |
| **Phase 9** | Production Polish, E2E & Final Deployment | Zero-downtime deployment, Vercel Web & Railway container | ⏸️ Queued | `phase-9-production-polish-deployment.md` |

---

# SECTION 2: CURRENT SYSTEM AUDIT & VULNERABILITY REGISTER

An in-depth, line-by-line inspection of the repository (`c:\DATA\Stuff\Project\SEM-9`) was executed across all PHP pages, API endpoints, includes, database dump files, and AI Python scripts.

### 2.1 Critical Security Vulnerabilities Found

| # | Vulnerability | Location | Severity | Description & Exploit Vector |
|---|---|---|---|---|
| **V-01** | **Exposed Live Hosting Credentials** | `db.php` (Lines 35–38) | **CRITICAL** | Production InfinityFree database host (`sql113.infinityfree.com`), username (`if0_42838894`), and plaintext password (`gDaughDyA4Dnmdw`) are committed directly to version control. Anyone cloning the repository has full database read/write access. |
| **V-02** | **Plaintext Staff Password Storage** | `db.php` (Line 327), `api/permissions.php` (Line 77) | **CRITICAL** | The `staff` table explicitly maintains a column `plain_password VARCHAR(100) DEFAULT 'staff123'`. The API exposes this in cleartext via `get_permissions` so the admin can view passwords. This breaches basic security tenets. |
| **V-03** | **Unauthenticated Biometric & GPS Spoofing** | `api/attendance_selfie.php` (Lines 31–38) | **HIGH** | The backend relies entirely on client assertion: `$face_verified = !empty($data['face_verified']) ? 1 : 0;` and `$location_verified = !empty($data['location_verified']) ? 1 : 0;`. No server-side facial vector verification or Haversine GPS distance calculation is performed on the server. |
| **V-04** | **Arbitrary Local OS Command Execution** | `api/backup.php` (Lines 331–362) | **HIGH** | The action `open_folder` executes `@pclose(popen('start "" explorer ...', "r"))` via PHP shell invocation. While intended for local Windows XAMPP desktop convenience, this is invalid and insecure in cloud container environments. |
| **V-05** | **AI SQL Injection & Unsafe Dynamic SQL Execution** | `ai/sql_sanitizer.php`, `api/chatbot.php` | **HIGH** | The AI assistant receives raw text, prompts Ollama to produce SQL, and uses naive regex search-and-replace (e.g. `preg_replace('/\bpassword\b/i', "'' as password")`) before executing it against MySQL via `$conn->query()`. A crafted prompt can bypass regex checks and exfiltrate data. |
| **V-06** | **Session-Only Authentication (No Stateless Tokens)** | `auth.php`, `api/auth.php` | **MEDIUM** | API endpoints rely on PHP `$_SESSION` cookies. Flutter mobile apps (Android APK) and separated Web SPAs cannot maintain PHP session state reliably across network drops or cross-origin headers without token management. |
| **V-07** | **Mixed Multi-Hospital Isolation Leaks** | `api/patients.php`, `api/beds.php`, `api/booking.php` | **MEDIUM** | Because `hospital_id` was added in a later migration, queries throughout the system use fallback clauses like `WHERE (hospital_id = ? OR hospital_id IS NULL)`. If an unassigned record exists, it leaks across hospital boundaries. |

### 2.2 Performance & Architecture Flaws in Current Codebase
1. **Database Bloat from Binary BLOBs**: `patient_files.file_data` is stored as `LONGBLOB`. Uploaded scans, PDFs, and high-resolution X-rays (up to 10MB each) are inserted directly into the MySQL InnoDB table space. This balloons table size, degrades memory caching, slows query response times, and complicates backups.
2. **Synchronous File Conversions**: Resizing and thumbnail generation (`createThumbnail` in `api/files.php`) run synchronously inside the HTTP POST request thread using GD library, blocking Apache worker threads during multi-file uploads.
3. **Fragile Client-Side Rendering**: PDF generation (`js/pdf-generator.js`) uses `html2canvas` to screenshot DOM nodes and convert them into canvas graphics, leading to blurry fonts, page-break clipping, and browser crashes on long medical dossiers.
4. **Tight Local Path Coupling**: `api/ai_train_api.php` hardcodes absolute developer paths: `'D:/xampp/htdocs/Hospital Management System'` and `'D:/ai_env/Scripts/python.exe'`.

---

# SECTION 3: EXISTING FEATURE INVENTORY

The codebase was audited to catalog every module, page, and feature with its real operational status:

| Module / Feature | Code Location | Status | Technical Reality in Repository |
|---|---|---|---|
| **Hospital Registration & Login** | `register_hospital.php`, `login.php`, `api/auth.php` | **Implemented & Verified** | Supports hospital creation with BCrypt passwords. Staff login detects `is_user = 1` and loads session permissions. |
| **Admin KPI Dashboard** | `dashboard.php`, `api/dashboard.php` | **Implemented & Verified** | Aggregates live patient counts, active queue, occupied beds, doctor counts, emergency cases, and daily staff attendance. |
| **Patient Registration & MRN** | `index.php`, `api/patients.php` | **Implemented & Verified** | Generates formatted MRN (`CP-YYYY-XXX`). Validates duplicates on name, surname, and father's name. |
| **Patient Directory & Search** | `patients.php`, `api/patients.php` | **Implemented & Verified** | Multi-term search with phone digit normalization and pagination. |
| **Patient Profile & Dossier** | `patient_profile.php`, `api/history.php` | **Implemented & Verified** | Displays medical history, past visits, timeline events, and prescriptions with frequency translations. |
| **Lifetime Patient QR Codes** | `patient_profile_qr.php`, `api/qr.php` | **Implemented & Verified** | Generates UUID v4 token stored in `patients.qr_token`. QR card modal prints patient identity slip. |
| **Camera QR Scanner** | `includes/qr_scanner_modal.php`, `js/qr-scanner.js` | **Implemented & Verified** | Uses `Html5Qrcode` scanner to read camera feed and redirect to `patient_profile.php?id=...`. |
| **Doctor Directory & Schedules** | `doctors.php`, `doctor_slots.php`, `api/doctors.php` | **Implemented & Verified** | Department association, per-day working hours, break times, and slot generation (15/30/45/60 min intervals). |
| **Appointment Booking & Anti-Bot** | `book.php`, `book_appointment.php`, `api/booking.php` | **Implemented & Verified** | Doctor slot selection, collision detection, and a math-based "Not-AI" verification challenge. |
| **Live Queue & Token Allocation** | `queue.php`, `api/queue.php` | **Implemented & Verified** | 4-stage queue progression with token assignment and advance check-in. |
| **4-Step Clinical Workstation** | `queue.php`, `api/consultation.php` | **Implemented & Verified** | Step 1 (Diagnoses), Step 2 (Prescriptions), Step 3 (Disposition/Beds/Tests), Step 4 (Advice/Summary/Files). |
| **Inpatient Bed & Ward Management**| `beds.php`, `api/beds.php` | **Implemented & Verified** | Interactive bed map (ICU, General Ward, Semi-Private). Bed occupancy tracking, patient admission, and discharge. |
| **Medical Files Gallery & Lightbox**| `patient_file_view.php`, `api/files.php`, `api/file.php`| **Implemented but Requires Improvement** | Binary BLOB storage in DB with thumbnail cache. Separate viewer modal with zoom. |
| **Staff Registry & Attendance** | `staff.php`, `api/staff.php` | **Implemented & Verified** | Daily roster, monthly sheet, shift timing, manual attendance marking, and bulk check-in. |
| **Selfie & Geofence Attendance** | `selfie_attendance.php`, `api/attendance_selfie.php` | **Broken / Insecure** | UI exists with `face-api.js` and GPS lookup, but backend validation is completely bypassed by client assertion. |
| **Staff Granular RBAC** | `staff_permissions.php`, `api/permissions.php` | **Implemented but Insecure** | 11 granular permission keys with role presets, but leaks plaintext staff passwords in the management UI. |
| **Online Consultation** | `online_consult.php`, `api/online_consultation.php`| **Partially Implemented** | Full clinical note-taking, file attachment, and fee tracking, but **no real-time audio/video WebRTC stream**. |
| **Consultation Charges Engine** | `charges.php`, `api/charges.php` | **Implemented & Verified** | CRUD for service fees (OPD, Specialist, Online Follow-up, PDF download). |
| **BHOOMA AI Assistant Chatbot** | `includes/chatbot_widget.php`, `api/chatbot.php`| **Implemented but Insecure** | Multi-turn chat, SSE streaming, action confirmation cards, but executes risky dynamic SQL queries. |
| **AI Action Review & Audit Trail** | `ai_logs.php`, `ai/action_engine.php` | **Implemented & Verified** | Logs pending mutations (INSERT/UPDATE/DELETE) with user confirmation requirement. |
| **GPU AI Training Dashboard** | `ai_training_dashboard.php`, `api/ai_train_api.php` | **Documented / Tied to Local Machine** | Dashboard renders telemetry and loss curves, but relies on local Windows paths and an RTX 4060 GPU. |
| **Database Backup & Restore** | `backup.php`, `restore.php`, `api/backup.php` | **Implemented but Insecure** | Full SQL dump with schema compatibility scanner, but calls local OS explorer and raw SQL uploads. |
| **PDF Prescription Printing** | `js/pdf-generator.js`, `api/pdf.php` | **Implemented but Low Quality** | Uses client-side DOM canvas rasterization (`html2canvas`), creating low-resolution documents. |

---

# SECTION 4: FEATURE PRESERVATION MATRIX

Every existing capability has been mapped directly to its target Flutter + NestJS + Supabase equivalent. No feature is silently dropped.

| # | Existing Feature | Disposition | Future Flutter Screens | Future NestJS API Endpoints | Target PostgreSQL Tables | Granular Permission | Phase |
|---|---|---|---|---|---|---|---|
| **1** | Hospital Multi-Tenancy & Auth | **Redesign** | `LoginScreen`, `HospitalRegistrationScreen` | `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh` | `hospitals`, `users`, `refresh_tokens` | Public / System | Phase 4 |
| **2** | Executive KPI Dashboard | **Redesign** | `AdminDashboardScreen`, `StaffDashboardScreen` | `GET /api/v1/dashboard/overview`, `GET /api/v1/dashboard/analytics` | Materialized views & aggregated queries | Authenticated | Phase 5 |
| **3** | Patient Registration & MRN | **Retain & Enhance** | `PatientRegistrationScreen`, `DuplicateCheckDialog` | `POST /api/v1/patients`, `POST /api/v1/patients/check-duplicate` | `patients` | `can_edit_patients` | Phase 5 |
| **4** | Patient Directory & Search | **Retain & Enhance** | `PatientDirectoryScreen` (Adaptive Table/Cards) | `GET /api/v1/patients?page=&q=` | `patients` | `can_view_patients` | Phase 5 |
| **5** | Patient Profile & Dossier | **Retain & Enhance** | `PatientProfileScreen`, `PatientTimelineView` | `GET /api/v1/patients/:id/dossier` | `patients`, `appointments`, `prescriptions`, `diagnoses`, `timeline_events` | `can_view_patients` | Phase 5 |
| **6** | Lifetime QR Generation & Lookup | **Retain & Enhance** | `PatientQrCardScreen`, `PrintableCardDialog` | `GET /api/v1/patients/qr/:token`, `POST /api/v1/patients/:id/qr` | `patients.qr_token` | `can_generate_qr` | Phase 8 |
| **7** | Mobile/Camera QR Scanner | **Redesign** | `QrScannerModal` (Mobile Camera / USB Barcode) | `GET /api/v1/patients/qr/:token` | `patients` | `can_view_patients` | Phase 8 |
| **8** | Doctor Profiles & Specializations | **Retain** | `DoctorDirectoryScreen`, `DoctorFormDialog` | `GET /api/v1/doctors`, `POST /api/v1/doctors` | `doctors`, `departments`, `doctor_categories` | Admin Only | Phase 5 |
| **9** | Doctor Schedules & Slot Engine | **Retain & Enhance** | `DoctorScheduleScreen`, `SlotConfigDialog` | `GET /api/v1/doctors/:id/slots`, `PUT /api/v1/doctors/:id/schedules` | `doctor_day_schedules`, `doctor_slots` | Admin Only | Phase 5 |
| **10**| Appointment Booking & Anti-Collision| **Retain & Enhance** | `AppointmentBookingScreen`, `SlotPickerWidget` | `POST /api/v1/appointments`, `GET /api/v1/appointments/check-token` | `appointments` | `can_manage_appointments` | Phase 5 |
| **11**| Live Patient Queue & Token Pipeline | **Retain & Enhance** | `QueuePipelineScreen` (Kanban / Step Board) | `GET /api/v1/queue`, `PATCH /api/v1/queue/:id/stage` | `appointments` | `can_assign_tokens` | Phase 5 |
| **12**| 4-Step Clinical Workstation | **Redesign & Polish** | `ClinicalWorkstationScreen` (Multi-tab Stepper) | `POST /api/v1/consultations/:appointmentId` | `diagnoses`, `prescriptions`, `timeline_events` | Doctor / RMO | Phase 5 |
| **13**| Latin Prescription Frequency Parser | **Retain** | Embedded in `PrescriptionBuilderWidget` | Validated in NestJS DTO | `prescriptions` | Doctor / RMO | Phase 5 |
| **14**| Medical File Uploads | **Redesign (Storage)**| `FileUploadDialog` (Drag-drop / Camera scan) | `POST /api/v1/files/upload-signed-url`, `POST /api/v1/files/confirm`| `patient_files` + Supabase Storage | `can_upload` | Phase 6 |
| **15**| Medical File Gallery & Viewer | **Redesign** | `MedicalGalleryScreen`, `InteractiveLightbox` | `GET /api/v1/files/patient/:id`, `GET /api/v1/files/:id/view-url` | `patient_files`, `file_audit_log` | `can_view_files` | Phase 6 |
| **16**| File Audit Logging | **Retain & Enhance** | `FileAuditLogScreen` | Logged automatically via NestJS Interceptor | `file_audit_log` | Admin Only | Phase 6 |
| **17**| Bed & Ward Management | **Retain & Enhance** | `BedWardMapScreen` (Interactive Bed Grid) | `GET /api/v1/beds`, `POST /api/v1/beds/admit`, `POST /api/v1/beds/discharge` | `beds`, `appointments` | Nurse / Admin | Phase 7 |
| **18**| Staff Directory & Credentials | **Redesign (Secure)** | `StaffDirectoryScreen`, `StaffFormDialog` | `GET /api/v1/staff`, `POST /api/v1/staff` (Hashed passwords only) | `staff`, `users` | Admin Only | Phase 7 |
| **19**| Daily & Monthly Staff Attendance | **Retain** | `AttendanceRosterScreen`, `MonthlyAttendanceMatrix` | `GET /api/v1/attendance/daily`, `POST /api/v1/attendance/mark` | `staff_attendance` | Admin Only | Phase 7 |
| **20**| Biometric & Geofenced Attendance | **Redesign (Secure)** | `SelfieCheckInScreen` (Native Camera + Geolocation) | `POST /api/v1/attendance/selfie-verify` (Server-side Haversine & embeddings)| `staff_attendance`, `hospital_geofence` | Staff | Phase 7 |
| **21**| 11+ Granular Permission Keys | **Retain & Strengthen**| `PermissionsManagerScreen`, `RolePresetSelector` | `GET /api/v1/permissions/:staffId`, `PUT /api/v1/permissions/:staffId` | `staff_permissions` | Admin Only | Phase 4 |
| **22**| Online Consultation Record & Billing | **Retain & Enhance** | `OnlineConsultationScreen` | `POST /api/v1/online-consultations`, `PATCH /api/v1/online-consultations/:id` | `online_consultations`, `consultation_charges` | `can_consult_online` | Phase 8 |
| **23**| Consultation Charges Matrix | **Retain** | `ChargesManagerScreen` | `GET /api/v1/charges`, `PUT /api/v1/charges/:id` | `consultation_charges` | Admin Only | Phase 7 |
| **24**| Native Vector PDF Slip Printing | **Redesign** | In-app Print Preview using `pdf` / `printing` | `GET /api/v1/reports/prescription/:id/pdf` | Pure PDF vector stream | `can_download_pdf` | Phase 8 |
| **25**| BHOOMA AI Clinical Assistant | **Redesign (Safe)** | `AiChatDrawerWidget`, `FloatingAiActionSheet` | `POST /api/v1/ai/chat` (SSE), `POST /api/v1/ai/confirm-action` | `ai_conversations`, `ai_messages`, `ai_pending_actions`, `ai_action_log`| Authenticated | Phase 8 |
| **26**| AI GPU Training Pipeline | **Deferred / Decoupled**| `AiModelTelemetryScreen` (Read-only status) | `GET /api/v1/ai/training-status` | `ai_config` | Admin Only | Phase 8 |
| **27**| Database Backup & PITR | **Redesign (Cloud)** | `CloudBackupStatusScreen` (Supabase Wal-G PITR)| `GET /api/v1/maintenance/backup-status`, `POST /api/v1/maintenance/export-dump`| Supabase Managed Infrastructure | Super Admin | Phase 9 |

---

# SECTION 5: TARGET ARCHITECTURE & BOUNDARIES

### 5.1 Architecture Overview
The modernized architecture enforces a strict separation between client applications, public API gateways, business application servers, and protected data repositories:

```mermaid
flowchart TB
    subgraph CLIENTS["📱 Multi-Platform Frontend (Flutter 3.x)"]
        WEB["Flutter Web (Wasm/CanvasKit)\nDeployed on Vercel Edge"]
        APK["Flutter Android APK\nSigned Release on Tablets/Phones"]
    end

    subgraph INGRESS["🛡️ Cloud Edge & Security"]
        DNS["Custom Domain DNS & SSL\n(Cloudflare / Vercel Edge)"]
        WAF["Rate Limiting & DDoS Shield"]
    end

    subgraph BACKEND["⚙️ Application Tier (Railway Container)"]
        NEST["NestJS Modular Monolith API (Node.js 20 LTS)\n• Passport JWT Authentication Guard\n• Centralized RBAC & Permission Interceptor\n• ValidationPipe (class-validator DTOs)\n• Structured Winston Audit Logger\n• Multi-Tenancy AsyncLocalStorage Context"]
    end

    subgraph AI_SERVICE["🤖 AI Integration Layer"]
        LLM["Cloud LLM Gateway\n(Groq / Together / Self-hosted Ollama Tunnel)\n• Tool Calling / Function Execution\n• Zero Raw SQL Execution\n• Human-in-the-Loop Mutation Gate"]
    end

    subgraph STORAGE["🗄️ Persistence Tier (Supabase Cloud India Region)"]
        PG["Supabase Managed PostgreSQL 15+\n• PgBouncer Connection Pooling\n• Row Level Security (RLS) Policies\n• Versioned Flyway/Prisma Migrations\n• Encrypted Automated Nightly Backups"]
        S3["Supabase Private Storage Buckets\n• AES-256 Server-Side Encryption\n• Short-Lived Signed Download URLs (15m)\n• Zero Public Object Access"]
    end

    WEB -->|HTTPS / WSS| INGRESS
    APK -->|HTTPS / WSS| INGRESS
    INGRESS -->|Validated Requests| NEST

    NEST -->|Connection Pool (Transaction Mode)| PG
    NEST -->|S3 Protocol / REST SDK| S3
    NEST -->|Streaming SSE / Function Tools| LLM

    APK -.->|Direct Signed URL Download| S3
    WEB -.->|Direct Signed URL Download| S3
```

### 5.2 Key Operational Boundaries & Rules
1. **Zero Database Exposure**: PostgreSQL is **never** accessible directly over the public internet by client applications. All reads, mutations, and searches pass through NestJS.
2. **Zero Service-Role Key Leaks**: The Supabase `service_role` secret is injected solely into Railway backend environment variables. Flutter Web and APK binaries receive only the unprivileged anonymous key (or zero Supabase keys, communicating exclusively through the NestJS REST API).
3. **Short-Lived Temporary File Access**: Medical records are stored in private Supabase Storage buckets. Clients never receive permanent public URLs. Instead, the backend verifies `can_view_files` permission and issues an authenticated **signed URL valid for exactly 15 minutes**.
4. **Tenant Isolation Guarantees**: Every database query is scoped by `hospital_id`. In PostgreSQL, foreign keys link records to `hospitals.id NOT NULL`. NestJS extracts `hospital_id` from the verified JWT payload, rendering cross-tenant data leakage structurally impossible.

---

# SECTION 6: ARCHITECTURE DIAGRAMS & REQUEST LIFECYCLES

### 6.1 Authentication & Request Lifecycle
```mermaid
sequenceDiagram
    autonumber
    actor Staff as Staff / Doctor
    participant UI as Flutter App (Web/APK)
    participant API as NestJS Backend (Railway)
    participant DB as Supabase PostgreSQL

    Staff->>UI: Enter Username & Password
    UI->>API: POST /api/v1/auth/login {username, password}
    Note over API: Rate limiter check (5 req/min)<br/>Lookup user by username
    API->>DB: SELECT * FROM staff JOIN users WHERE username = $1
    DB-->>API: Return User Record + Salt + Password Hash
    Note over API: Argon2id / BCrypt verify<br/>Verify account_status == 'Active'
    API->>DB: SELECT permission_key FROM staff_permissions WHERE staff_id = $1 AND permission_value = true
    DB-->>API: Active Permission Keys
    Note over API: Generate JWT Access Token (15m exp)<br/>Generate Cryptographic Refresh Token (7d exp)
    API-->>UI: 200 OK {accessToken, refreshToken, userProfile, permissions}
    Note over UI: Store Access Token in Memory<br/>Store Refresh Token in SecureStorage / HttpOnly Cookie

    Staff->>UI: Click "View Patient Directory"
    UI->>API: GET /api/v1/patients?page=1 [Header: Bearer JWT]
    Note over API: JwtAuthGuard validates signature & expiry<br/>PermissionsGuard checks 'can_view_patients'<br/>Extract hospital_id from JWT payload
    API->>DB: SELECT * FROM patients WHERE hospital_id = $tenantId ORDER BY created_at DESC LIMIT 15
    DB-->>API: 15 Patient Records
    API-->>UI: 200 OK {data: [...], meta: {total, page, limit}}
    UI-->>Staff: Render Adaptive Patient Cards / Table
```

### 6.2 Medical File Upload & Private Storage Lifecycle
```mermaid
sequenceDiagram
    autonumber
    actor Doctor as Doctor / Lab Technician
    participant UI as Flutter App
    participant API as NestJS Backend
    participant S3 as Supabase Storage (Private)
    participant DB as Supabase PostgreSQL

    Doctor->>UI: Selects X-Ray Scan (10MB PNG)
    Note over UI: Validate client MIME & file size (<15MB)
    UI->>API: POST /api/v1/files/request-upload {patientId, fileName, mimeType, category}
    Note over API: Verify 'can_upload' permission<br/>Sanitize filename<br/>Generate Storage Key: /hosp_{id}/pat_{id}/{uuid}.png
    API->>S3: Create Pre-Signed Upload URL (PUT, expires in 5 min)
    S3-->>API: Return Signed Upload URL
    API-->>UI: 200 OK {uploadUrl, fileKey, tempId}

    UI->>S3: Direct Binary Upload (PUT uploadUrl, Binary Stream)
    S3-->>UI: 200 Upload Completed

    UI->>API: POST /api/v1/files/confirm-upload {tempId, fileKey, patientId, category, tags}
    Note over API: Verify object exists in bucket via HeadObject<br/>Inspect file size and headers
    API->>DB: INSERT INTO patient_files (hospital_id, patient_id, storage_key, mime_type, file_size, category, uploaded_by)
    API->>DB: INSERT INTO file_audit_log (action: 'upload', patient_id, staff_id)
    DB-->>API: File Record Created (ID: 412)
    API-->>UI: 201 Created {fileId: 412, status: 'Archived'}
    UI-->>Doctor: Show Success Banner & Update Gallery
```

---

# SECTION 7: DATABASE REDESIGN — MYSQL TO POSTGRESQL

### 7.1 Key Schema Migration Principles
1. **Identity Columns**: Replace MySQL `AUTO_INCREMENT` with PostgreSQL `GENERATED ALWAYS AS IDENTITY`.
2. **UUID Support**: Utilize native PostgreSQL `UUID` for system tokens and public references, while preserving existing clinical MRN patterns (`CP-YYYY-XXX`) for patient readability.
3. **Strict Temporal Types**: Replace loose MySQL `VARCHAR(10)` time strings with standard `TIMESTAMPTZ`, `DATE`, and `TIME`.
4. **Relational Normalization**: Eliminate duplicate denormalized columns (`patients.demographics` which duplicated age, gender, and blood group). Store structured fields in dedicated typed columns and generate computed views if needed.
5. **No Files in Database**: Eliminate `file_data LONGBLOB`. The `patient_files` table stores only metadata, tags, and object storage paths (`storage_path`).

### 7.2 Entity Relationship Diagram (PostgreSQL)

```mermaid
erDiagram
    HOSPITALS ||--o{ PATIENTS : "registers"
    HOSPITALS ||--o{ DEPARTMENTS : "operates"
    HOSPITALS ||--o{ DOCTORS : "employs"
    HOSPITALS ||--o{ STAFF : "employs"
    HOSPITALS ||--o{ BEDS : "maintains"
    HOSPITALS ||--o{ CONSULTATION_CHARGES : "sets"
    HOSPITALS ||--o{ HOSPITAL_GEOFENCE : "defines"

    DEPARTMENTS ||--o{ DOCTOR_CATEGORIES : "categorizes"
    DOCTORS ||--o{ DOCTOR_CATEGORIES : "specializes"
    DOCTORS ||--o{ DOCTOR_DAY_SCHEDULES : "works"
    DOCTORS ||--o{ DOCTOR_SLOTS : "allocates"

    PATIENTS ||--o{ APPOINTMENTS : "books"
    DOCTORS ||--o{ APPOINTMENTS : "attends"
    BEDS ||--o| APPOINTMENTS : "assigns"

    APPOINTMENTS ||--o{ DIAGNOSES : "concludes"
    APPOINTMENTS ||--o{ PRESCRIPTIONS : "prescribes"
    APPOINTMENTS ||--o{ TIMELINE_EVENTS : "logs"
    APPOINTMENTS ||--o{ PATIENT_FILES : "attaches"

    PATIENTS ||--o{ PATIENT_FILES : "owns"
    PATIENTS ||--o{ ONLINE_CONSULTATIONS : "participates"
    DOCTORS ||--o{ ONLINE_CONSULTATIONS : "conducts"

    STAFF ||--o{ STAFF_ATTENDANCE : "submits"
    STAFF ||--o{ STAFF_PERMISSIONS : "holds"
    STAFF ||--o{ FILE_AUDIT_LOG : "triggers"

    HOSPITALS ||--o{ AI_CONFIG : "configures"
    STAFF ||--o{ AI_CONVERSATIONS : "initiates"
    AI_CONVERSATIONS ||--o{ AI_MESSAGES : "contains"
    AI_CONVERSATIONS ||--o{ AI_PENDING_ACTIONS : "triggers"
    AI_PENDING_ACTIONS ||--o| AI_ACTION_LOG : "audits"
```

### 7.3 Complete Production PostgreSQL DDL Migration Script

```sql
-- ============================================================================
-- HOSPITAL MANAGEMENT SYSTEM (HMS) MODERNIZATION SCHEMA
-- Dialect: PostgreSQL 15+ (Supabase Managed)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. HOSPITALS (Multi-Tenancy Foundation)
CREATE TABLE hospitals (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    tagline VARCHAR(255) DEFAULT 'Medicare Hospital & I.C.U',
    phone VARCHAR(30),
    email VARCHAR(150),
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. DEPARTMENTS
CREATE TABLE departments (
    id VARCHAR(100) PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    icon VARCHAR(60) DEFAULT 'fa-hospital',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_departments_hospital ON departments(hospital_id);

-- 3. DOCTORS
CREATE TABLE doctors (
    id VARCHAR(50) PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    department_id VARCHAR(100) REFERENCES departments(id) ON DELETE SET NULL,
    phone VARCHAR(50),
    degree VARCHAR(150),
    experience VARCHAR(50),
    consultation_fee NUMERIC(10, 2) DEFAULT 500.00,
    status VARCHAR(30) DEFAULT 'Available',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_doctors_hospital ON doctors(hospital_id);

-- 4. DOCTOR CATEGORIES (Many-to-Many Specialty Mapping)
CREATE TABLE doctor_categories (
    doctor_id VARCHAR(50) NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    department_id VARCHAR(100) NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, department_id)
);

-- 5. DOCTOR DAY SCHEDULES
CREATE TABLE doctor_day_schedules (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id VARCHAR(50) NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day_of_week VARCHAR(20) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE NOT NULL,
    start_time TIME NOT NULL DEFAULT '09:00:00',
    end_time TIME NOT NULL DEFAULT '17:00:00',
    duration_minutes INT NOT NULL DEFAULT 30,
    break_start TIME,
    break_end TIME,
    custom_slots JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_doctor_day UNIQUE (doctor_id, day_of_week)
);
CREATE INDEX idx_doc_sched_doc ON doctor_day_schedules(doctor_id);

-- 6. DOCTOR SLOTS (Explicit Slot Registry)
CREATE TABLE doctor_slots (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id VARCHAR(50) NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    time_slot VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_doc_slots_doctor ON doctor_slots(doctor_id);

-- 7. PATIENTS
CREATE TABLE patients (
    id VARCHAR(50) PRIMARY KEY, -- Clinical MRN: 'CP-2026-001'
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    father_name VARCHAR(100),
    phone VARCHAR(30),
    age INT CHECK (age >= 0 AND age <= 130),
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group VARCHAR(10) CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    emergency_contact_name VARCHAR(150),
    emergency_contact_phone VARCHAR(30),
    qr_token UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
    qr_generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_patients_hospital ON patients(hospital_id);
CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_search ON patients(name, surname);
CREATE INDEX idx_patients_qr ON patients(qr_token);

-- 8. BEDS & WARDS
CREATE TABLE beds (
    id VARCHAR(50) PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    bed_number VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('ICU', 'General Ward', 'Private Room', 'Semi-Private', 'Emergency')),
    wing VARCHAR(100) DEFAULT 'Main Ward',
    status VARCHAR(30) DEFAULT 'Available' CHECK (status IN ('Available', 'Occupied', 'Maintenance', 'Sanitizing')),
    patient_id VARCHAR(50) REFERENCES patients(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_hospital_bed UNIQUE (hospital_id, bed_number)
);
CREATE INDEX idx_beds_hospital_status ON beds(hospital_id, status);

-- 9. APPOINTMENTS
CREATE TABLE appointments (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id VARCHAR(50) NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    type VARCHAR(100) DEFAULT 'General Consultation',
    date DATE NOT NULL,
    slot VARCHAR(30) NOT NULL,
    token_number INT,
    token_assigned_at TIMESTAMPTZ,
    token_assigned_by INT,
    symptoms TEXT,
    allergies TEXT,
    status VARCHAR(50) DEFAULT 'Scheduled',
    stage INT DEFAULT 1 CHECK (stage BETWEEN 0 AND 5),
    bed_number VARCHAR(50),
    doctor_notes TEXT,
    booking_type VARCHAR(30) DEFAULT 'walk-in' CHECK (booking_type IN ('walk-in', 'online', 'referral')),
    booking_ref VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_appointments_hospital_date ON appointments(hospital_id, date);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor_date ON appointments(doctor_id, date, slot);

-- 10. DIAGNOSES
CREATE TABLE diagnoses (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INT NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    icd10_code VARCHAR(20),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_diagnoses_appointment ON diagnoses(appointment_id);

-- 11. PRESCRIPTIONS
CREATE TABLE prescriptions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INT NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration VARCHAR(100) NOT NULL,
    instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_prescriptions_appointment ON prescriptions(appointment_id);

-- 12. TIMELINE EVENTS
CREATE TABLE timeline_events (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INT REFERENCES appointments(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    event_time VARCHAR(50) NOT NULL,
    event_description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_timeline_patient ON timeline_events(patient_id);
CREATE INDEX idx_timeline_appointment ON timeline_events(appointment_id);

-- 13. PATIENT MEDICAL FILES (Metadata Only - Objects in Supabase Storage)
CREATE TABLE patient_files (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_id INT REFERENCES appointments(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(60) NOT NULL DEFAULT 'Other',
    highlight VARCHAR(255),
    description TEXT,
    storage_path VARCHAR(500) NOT NULL, -- Path in Supabase Storage: hosp_1/pat_CP-2026-001/uuid.jpg
    thumbnail_path VARCHAR(500),
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    tags VARCHAR(500),
    uploaded_by_id INT,
    uploaded_by_name VARCHAR(150),
    record_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_patient_files_patient ON patient_files(patient_id);
CREATE INDEX idx_patient_files_appointment ON patient_files(appointment_id);

-- 14. STAFF & PORTAL USERS
CREATE TABLE staff (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    staff_code VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(50),
    role VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    gender VARCHAR(20) DEFAULT 'Female',
    date_of_birth DATE,
    joining_date DATE,
    shift VARCHAR(100) DEFAULT 'Morning (08:00 - 16:00)',
    status VARCHAR(30) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Terminated', 'On Leave')),
    qualification VARCHAR(255),
    salary NUMERIC(12, 2) DEFAULT 0.00,
    blood_group VARCHAR(10),
    emergency_contact VARCHAR(100),
    address TEXT,
    is_user BOOLEAN DEFAULT FALSE NOT NULL,
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255), -- Argon2id / BCrypt ONLY (plain_password permanently removed)
    avatar_url VARCHAR(500),
    face_embedding JSONB DEFAULT NULL, -- 128-float biometric descriptor vector
    account_status VARCHAR(30) DEFAULT 'Active' CHECK (account_status IN ('Active', 'Blocked', 'Suspended')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_staff_hospital_code UNIQUE (hospital_id, staff_code)
);
CREATE INDEX idx_staff_hospital ON staff(hospital_id);
CREATE INDEX idx_staff_username ON staff(username);

-- 15. STAFF PERMISSIONS
CREATE TABLE staff_permissions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    permission_key VARCHAR(60) NOT NULL,
    permission_value BOOLEAN DEFAULT FALSE NOT NULL,
    granted_by INT,
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_staff_perm UNIQUE (staff_id, permission_key)
);
CREATE INDEX idx_staff_permissions_staff ON staff_permissions(staff_id);

-- 16. HOSPITAL GEOFENCE
CREATE TABLE hospital_geofence (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    name VARCHAR(100) DEFAULT 'Main Clinical Building',
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    radius_meters INT DEFAULT 150 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_geofence_hospital ON hospital_geofence(hospital_id);

-- 17. STAFF ATTENDANCE
CREATE TABLE staff_attendance (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    staff_id INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Present' CHECK (status IN ('Present', 'Absent', 'Late', 'Half Day', 'On Leave')),
    check_in_time TIME,
    check_out_time TIME,
    working_hours NUMERIC(4, 2),
    selfie_verified BOOLEAN DEFAULT FALSE NOT NULL,
    location_verified BOOLEAN DEFAULT FALSE NOT NULL,
    check_in_lat NUMERIC(10, 7),
    check_in_lng NUMERIC(10, 7),
    face_confidence NUMERIC(5, 4),
    check_in_method VARCHAR(30) DEFAULT 'manual',
    marked_by VARCHAR(100) DEFAULT 'System',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_staff_attendance_day UNIQUE (staff_id, date)
);
CREATE INDEX idx_attendance_hospital_date ON staff_attendance(hospital_id, date);

-- 18. CONSULTATION CHARGES
CREATE TABLE consultation_charges (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    charge_type VARCHAR(100) NOT NULL,
    charge_name VARCHAR(255) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_charges_hospital ON consultation_charges(hospital_id);

-- 19. ONLINE CONSULTATIONS
CREATE TABLE online_consultations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id VARCHAR(50) NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    appointment_id INT REFERENCES appointments(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'initiated' CHECK (status IN ('initiated', 'in_progress', 'completed', 'cancelled')),
    diagnosis TEXT,
    prescription_notes TEXT,
    doctor_notes TEXT,
    consultation_fee NUMERIC(10, 2) DEFAULT 0.00,
    fee_status VARCHAR(30) DEFAULT 'pending' CHECK (fee_status IN ('pending', 'paid', 'waived')),
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMPTZ
);
CREATE INDEX idx_online_consult_hospital ON online_consultations(hospital_id);
CREATE INDEX idx_online_consult_patient ON online_consultations(patient_id);

-- 20. FILE AUDIT LOG
CREATE TABLE file_audit_log (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL,
    file_id INT REFERENCES patient_files(id) ON DELETE SET NULL,
    action VARCHAR(30) NOT NULL CHECK (action IN ('upload', 'view', 'edit', 'delete', 'download')),
    staff_id INT NOT NULL,
    staff_name VARCHAR(200) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_file_audit_patient ON file_audit_log(patient_id);
CREATE INDEX idx_file_audit_hospital_date ON file_audit_log(hospital_id, created_at);

-- 21. AI ENGINE TABLES
CREATE TABLE ai_config (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE UNIQUE,
    enabled BOOLEAN DEFAULT TRUE NOT NULL,
    model_name VARCHAR(100) DEFAULT 'qwen2.5:3b',
    provider VARCHAR(50) DEFAULT 'ollama', -- 'ollama', 'groq', 'together'
    api_url VARCHAR(255) DEFAULT 'http://localhost:11434',
    max_tokens INT DEFAULT 2048,
    temperature NUMERIC(3, 2) DEFAULT 0.20,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE ai_conversations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL,
    user_role VARCHAR(100) DEFAULT 'Admin',
    title VARCHAR(255) DEFAULT 'Clinical Query',
    page_context VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_ai_conv_hospital_user ON ai_conversations(hospital_id, user_id);

CREATE TABLE ai_chat_messages (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversation_id INT NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tool_calls JSONB DEFAULT NULL,
    tokens_used INT DEFAULT 0,
    response_time_ms INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_ai_msg_conv ON ai_chat_messages(conversation_id);

CREATE TABLE ai_pending_actions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversation_id INT NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    action_type VARCHAR(30) NOT NULL CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    target_table VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'expired', 'executed', 'failed')),
    confirmed_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ,
    error_message TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_ai_pending_status ON ai_pending_actions(status, expires_at);

CREATE TABLE ai_action_log (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INT NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL,
    user_role VARCHAR(100) NOT NULL,
    action_id INT REFERENCES ai_pending_actions(id) ON DELETE SET NULL,
    action_type VARCHAR(30) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    mutation_details JSONB NOT NULL,
    success BOOLEAN DEFAULT TRUE NOT NULL,
    error_message TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_ai_action_log_hosp ON ai_action_log(hospital_id, created_at);
```

---

# SECTION 8: MEDICAL IMAGES & DOCUMENT STORAGE ARCHITECTURE

### 8.1 Elimination of MySQL BLOBs
Storing binaries in MySQL tables via `LONGBLOB` creates significant operational bottlenecks:
- Increases database size by gigabytes of unstructured data.
- Pollutes buffer pool memory caches during simple table scans.
- Severely prolongs database backup dumps and restores.

### 8.2 Private Object Storage Strategy (Supabase Storage)
The modernized design utilizes private **Supabase Storage** (backed by AWS S3 infrastructure in AWS ap-south-1 Mumbai):

1. **Bucket Structure**:
   - `medical-records` (Bucket visibility: **Strictly Private**)
   - Object Key Naming Convention:
     `hosp_{hospital_id}/pat_{patient_id}/{year}/{uuidv4}_{sanitized_original_name}.{ext}`
   - `staff-avatars` (Bucket visibility: **Private, Signed Access**)
     `hosp_{hospital_id}/staff_{staff_id}/{uuidv4}.jpg`

2. **Validation & Size Limits**:
   - Maximum upload payload: **15 MB per file**.
   - Allowed MIME types:
     - Images: `image/jpeg`, `image/png`, `image/webp`
     - Clinical Documents: `application/pdf`
     - Diagnostic Imagery: `image/tiff`, `image/bmp`
   - Client and Server Magic Number (file header) validation before S3 commit.

3. **Secure Download Workflow (Short-Lived Signed URLs)**:
   - When a Flutter client requests a file preview or lightbox zoom, it invokes `GET /api/v1/files/:id/signed-url`.
   - NestJS verifies user authentication, checks `can_view_files` permission, confirms patient hospital tenancy, and records an entry into `file_audit_log`.
   - NestJS calls Supabase Storage API:
     ```typescript
     const { data, error } = await supabase.storage
       .from('medical-records')
       .createSignedUrl(file.storage_path, 900); // Exactly 900 seconds (15 mins)
     ```
   - The Flutter client streams the image directly from the edge CDN using the pre-signed URL.

4. **Malware Defense & Storage Quarantine**:
   - Uploaded files are initially marked with `status = 'pending_scan'`.
   - A serverless or background worker verifies file headers and structure before marking `status = 'ready'`.

---

# SECTION 9: AUTHENTICATION, PERMISSIONS & HEALTHCARE SECURITY

### 9.1 Authentication Architecture (Dual-Token JWT)
1. **Access Token**: Short-lived JWT (15 minutes). Signed with RS256 or HS256 secret. Contains:
   ```json
   {
     "sub": 104,
     "username": "nurse.mary",
     "hospital_id": 1,
     "role": "Nurse",
     "permissions": ["can_upload", "can_view_patients", "can_assign_tokens"]
   }
   ```
2. **Refresh Token**: Cryptographically secure 64-byte random token stored in an encrypted database table with family tracking to detect token reuse. Expiration: 7 days.
3. **Storage in Flutter**:
   - **Flutter Web**: Stored in memory; refresh token held in `HttpOnly`, `SameSite=Strict`, `Secure` cookie to mitigate XSS attacks.
   - **Flutter Android**: Stored in `flutter_secure_storage` (backed by Android Keystore and EncryptedSharedPreferences).

### 9.2 The 11 Granular Staff Permissions
Permissions are modeled as first-class authorization keys:
1. `can_upload` — Upload diagnostic reports, scans, and documents.
2. `can_view_files` — View and inspect patient archive files and lightboxes.
3. `can_edit_files` — Modify document titles, tags, and categories.
4. `can_delete_files` — Remove files from the patient archive (Soft delete).
5. `can_view_patients` — Search and view the patient directory and registration cards.
6. `can_edit_patients` — Edit demographic data, phone numbers, and emergency contacts.
7. `can_manage_appointments` — Create, reschedule, and cancel clinical bookings.
8. `can_assign_tokens` — Allocate and reorder live triage tokens in the queue.
9. `can_generate_qr` — Generate or regenerate permanent patient QR cards.
10. `can_download_pdf` — Export printable clinical dossiers and prescription slips.
11. `can_consult_online` — Access the remote online consultation terminal and billing.

### 9.3 Server-Side Biometric & Geofence Verification
Unlike the legacy implementation where the client sent `face_verified: 1`, the modern backend recalculates all constraints:
1. **GPS Geofence Validation**: The client transmits device coordinates and accuracy. NestJS executes the Haversine equation against the hospital's registered boundary:
   \[
   d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)
   \]
   If $d > \text{radius\_meters}$, the request is rejected with `GEOFENCE_VIOLATION`.
2. **Facial Recognition**: The client computes a 128-float face descriptor vector using TensorFlow Lite on Android or WebAssembly on Web. NestJS computes Euclidean Distance against the stored reference vector:
   \[
   \text{Distance} = \sqrt{\sum_{i=1}^{128} (v_{1}[i] - v_{2}[i])^2}
   \]
   Verification succeeds only if $\text{Distance} < 0.60$.

### 9.4 Regulatory & Compliance Context (India)
1. **DPDPA (Digital Personal Data Protection Act 2023)**:
   - Requires explicit patient consent for data collection.
   - Requires verifiable audit logs of who accessed or modified patient data.
   - Data must be hosted within permitted jurisdictions (AWS Mumbai ap-south-1 aligns with Indian residency preferences).
2. **DISHA (Digital Information Security in Healthcare Act)**:
   - Prohibits storage of clinical passwords in plaintext.
   - Mandates end-to-end encryption in transit (TLS 1.3) and at rest (AES-256).

---

# SECTION 10: FLUTTER UI/UX DESIGN SYSTEM

### 10.1 Clinical Design Philosophy
The UI follows a calm, high-contrast, distraction-free aesthetic:
- **Primary Color Palette**:
  - Primary Slate: `#0F172A` (Tailwind `slate-900`)
  - Pure Black Accents: `#000000` (Uniform navigation icons and brand badges)
  - Medical Blue / Indigo: `#3B82F6` / `#4F46E5` (Active states and CTA buttons)
  - Clinical Emerald: `#10B981` (Success, available beds, on-time attendance)
  - Critical Amber / Rose: `#F59E0B` / `#EF4444` (Emergency cases, occupied beds, warnings)
  - Background Neutral: `#F8FAFC` (Clean canvas avoiding eye fatigue)
- **Typography**: Inter / Roboto font family with crisp tabular numerals (`font-variant-numeric: tabular-nums`) for vitals, dates, and token numbers.
- **Glass-Morphism Elements**: Subtle backdrop blurs (`BackdropFilter`) with translucent white cards (`rgba(255,255,255,0.85)`) and 1px borders (`#E2E8F0`).

### 10.2 Adaptive Multi-Platform Layout Breakpoints
The Flutter app detects screen real estate and adjusts navigation structures:
- **Desktop / Workstation (`width >= 1024px`)**:
  - Permanent 260px collapsible sidebar with categorized accordions.
  - Multi-column data layouts (e.g., Clinical Workstation: 3 columns—patient vitals, 4-step stepper, consultation history).
  - Keyboard shortcuts (`Ctrl+K` for AI assistant, `Ctrl+F` for patient search).
- **Tablet (`768px <= width < 1024px`)**:
  - Collapsible navigation rail.
  - 2-column clinical workflows.
- **Mobile Handheld (`width < 768px`)**:
  - Bottom navigation bar with 4 primary destinations (Dashboard, Patients, Queue, Profile).
  - Modal bottom sheets (`showModalBottomSheet`) instead of wide dialog boxes.
  - Large touch targets (minimum 48×48 dp).

---

# SECTION 11: SCREEN-BY-SCREEN SPECIFICATION

Below is the exhaustive catalog of 35 production Flutter screens and modal components:

```
Flutter Screens Catalog:
├── 1.  LoginScreen (Username, Password, Hospital Code, Animated Logo)
├── 2.  HospitalRegistrationScreen (New Hospital Onboarding)
├── 3.  AdminDashboardScreen (KPI Stats, Emergency Alert Banners, Daily Summary)
├── 4.  StaffDashboardScreen (Role-Tailored Hub, Quick Shortcuts)
├── 5.  PatientDirectoryScreen (Searchable Table, Filter Pills, Action Buttons)
├── 6.  PatientRegistrationScreen (Adaptive Multi-Step Form with Duplicate Detection)
├── 7.  PatientProfileScreen (Demographics, Past Visits, Vitals, Timeline)
├── 8.  PatientQrCardScreen (Printable & Downloadable Lifetime QR Identity Card)
├── 9.  QrScannerModalScreen (Camera Viewfinder with Laser Scanner & Audio Beep)
├── 10. AppointmentCalendarScreen (Day/Week Grid, Doctor Availability Markers)
├── 11. AppointmentBookingDialog (Slot Picker, Anti-Bot Challenge, Duplicate Guard)
├── 12. DoctorScheduleScreen (Per-Day Working Hours, Break Slot Controls)
├── 13. QueuePipelineScreen (Triage Kanban, Token Sequencer, Call Next Patient)
├── 14. ClinicalWorkstationScreen (4-Step Consultation: Diagnoses, Rx, Disposition, Notes)
├── 15. PrescriptionSlipScreen (Print-Ready Vector Prescription Layout)
├── 16. MedicalGalleryScreen (Categorized Grid: X-Ray, Blood, ECG, Ultrasound)
├── 17. MedicalFileLightboxScreen (Full-Screen Image Zoom, Pan, PDF Viewer)
├── 18. FileUploadDialog (Multi-File Selector, Metadata Tagger, Upload Progress)
├── 19. FileAuditLogScreen (Searchable Access Trail: Upload, View, Delete)
├── 20. BedWardMapScreen (Visual Bed Grid: ICU, General, Semi-Private, Occupancy)
├── 21. BedAdmissionDialog (Patient Selector, Admitting Doctor, Diagnosis)
├── 22. StaffDirectoryScreen (Employee Profiles, Roles, Shift Schedules)
├── 23. StaffProfileScreen (Qualifications, Contact, Emergency Info, Salary)
├── 24. AttendanceRosterScreen (Daily Attendance Table, Check-In Times, Statuses)
├── 25. MonthlyAttendanceMatrixScreen (Day-by-Day Grid with Monthly % Stats)
├── 26. SelfieAttendanceScreen (Face Camera Viewfinder, Biometric & GPS Matcher)
├── 27. PermissionsManagerScreen (Staff Account Toggle, 11 Granular Perm Switches)
├── 28. OnlineConsultationScreen (Remote Clinical Note Taking, Fee Collection)
├── 29. ChargesManagerScreen (Service Charge Pricing Matrix)
├── 30. BhoomaAiChatScreen (Conversational Clinical Interface, Stream Responses)
├── 31. AiActionReviewDialog (Human-in-the-Loop Confirmation Cards for DB Mutations)
├── 32. AiLogsScreen (Audit History of AI-Generated Actions)
├── 33. SystemSettingsScreen (Hospital Name, Tagline, Address, Working Hours)
├── 34. UserSecuritySettingsScreen (Change Password, MFA Setup, Session Revocation)
└── 35. StateFeedbackScreens (AccessDeniedScreen, NotFoundScreen, OfflineScreen)
```

### ASCII Wireframe: 4-Step Clinical Workstation (`ClinicalWorkstationScreen`)
```text
+--------------------------------------------------------------------------------------------------+
| BHOOMA MEDICARE HOSPITAL | Clinical Workstation                 Doctor: Dr. Ambarish Kulkarni   |
+--------------------------------------------------------------------------------------------------+
| PATIENT: CP-2026-004 | Dev Patel | 42 Y, Male, B+ | BP: 120/80 | Temp: 98.6 F | Token #03       |
+--------------------------------------------------------------------------------------------------+
| [1. Diagnoses] ---> [2. Prescriptions] ---> [3. Disposition & Tests] ---> [4. Advice & Summary] |
+--------------------------------------------------------------------------------------------------+
| STEP 2: PRESCRIPTION BUILDER                                                                     |
|                                                                                                  |
| Medicine Name               Dosage     Frequency        Duration     Instructions                |
| +-------------------------+ +--------+ +--------------+ +----------+ +-------------------------+ |
| | Paracetamol 500mg     v | | 1 Tab  | | TID (3x Day) | | 5 Days   | | After meals             | |
| +-------------------------+ +--------+ +--------------+ +----------+ +-------------------------+ |
| | Amoxicillin 250mg     v | | 1 Cap  | | BID (2x Day) | | 7 Days   | | Before meals with water | |
| +-------------------------+ +--------+ +--------------+ +----------+ +-------------------------+ |
| [+ Add Another Medicine]                                                                         |
|                                                                                                  |
| FREQUENCY PRESETS: [OD - Once Daily] [BID - Twice Daily] [TID - 3x Daily] [QID] [SOS - As Needed]|
+--------------------------------------------------------------------------------------------------+
| [<< Back: Diagnoses]                                     [Proceed to Step 3: Disposition >>]     |
+--------------------------------------------------------------------------------------------------+
```

---

# SECTION 12: CORE USER WORKFLOWS

### Workflow A: Patient Registration & Duplicate Prevention
1. Receptionist opens `PatientRegistrationScreen`.
2. Enters Name, Surname, Father's Name, Phone, Age, Gender, Blood Group.
3. As fields lose focus, NestJS triggers `POST /api/v1/patients/check-duplicate`.
4. If a match is found on Name + Surname + Phone, an alert dialog displays the existing patient profile with a button: `[Open Existing Profile]` or `[Confirm New Patient]`.
5. On submit, NestJS allocates the next MRN atomically (`CP-YYYY-XXX`) via database transaction and generates a permanent `qr_token`.
6. UI displays the `PatientQrCardScreen` with print/download options.

### Workflow B: Appointment Booking & Collision Prevention
1. Receptionist selects Department -> Doctor -> Consultation Date.
2. NestJS returns doctor day schedules and currently booked slots.
3. Receptionist selects available slot (e.g. `10:30 AM`).
4. On submission, NestJS starts a database transaction with `SERIALIZABLE` or `SELECT ... FOR UPDATE` isolation to guarantee no concurrent double-booking of the same doctor slot occurs.
5. System computes the next sequential token number for the doctor for that date.
6. Record is inserted into `appointments`.

### Workflow C: 4-Step Clinical Workstation Execution
1. Doctor opens `QueuePipelineScreen` and clicks `[Call Next Patient]`.
2. Appointment status transitions to `In-Consultation` (Stage 2).
3. **Step 1 (Diagnoses)**: Doctor enters clinical findings and ICD-10 search terms.
4. **Step 2 (Prescriptions)**: Doctor selects medicines, dosages, and Latin frequencies (`TID`, `BID`, etc.), automatically translated into patient-readable advice.
5. **Step 3 (Disposition & Tests)**:
   - If *Discharged*: Appointment marked complete, stage advances to 5.
   - If *Waiting for Reports*: Doctor types required diagnostic lab tests. Appointment stage sets to 3, leaving bed unassigned.
   - If *Admitted (Ward/ICU)*: Modal prompts bed assignment. Bed status updates to `Occupied` transactionally.
6. **Step 4 (Advice & Summary)**: Doctor adds clinical notes and letterhead files.
7. Complete transaction commits to `appointments`, `diagnoses`, `prescriptions`, `timeline_events`, and `beds`.

---

# SECTION 13: BACKEND API INVENTORY (NESTJS REST)

Every endpoint follows standard REST conventions under `/api/v1` with JSON input/output:

### 13.1 Authentication & Profile
- `POST /api/v1/auth/register-hospital` — Register new hospital tenant.
- `POST /api/v1/auth/login` — Authenticate username & password; issues access and refresh tokens.
- `POST /api/v1/auth/refresh` — Issue new access token from valid refresh token.
- `POST /api/v1/auth/logout` — Revoke refresh token and invalidate session.
- `GET  /api/v1/auth/me` — Retrieve logged-in staff profile, role, and permissions.

### 13.2 Patients
- `GET    /api/v1/patients` — Paginated patient directory with search (`?page=1&limit=15&q=`).
- `GET    /api/v1/patients/:id` — Full patient demographics.
- `GET    /api/v1/patients/:id/dossier` — Complete clinical history, visits, prescriptions, and files.
- `POST   /api/v1/patients` — Register new patient.
- `POST   /api/v1/patients/check-duplicate` — Check duplicate name/phone combinations.
- `PUT    /api/v1/patients/:id` — Update patient records (`can_edit_patients`).
- `DELETE /api/v1/patients/:id` — Soft-delete patient record (Admin only).
- `GET    /api/v1/patients/qr/:token` — Resolve patient record from scanned QR token.

### 13.3 Appointments & Queue
- `GET   /api/v1/appointments` — Filter appointments by date, doctor, or status.
- `POST  /api/v1/appointments` — Book new appointment with anti-collision check.
- `GET   /api/v1/appointments/check-token` — Validate token number availability.
- `GET   /api/v1/queue` — Retrieve active triage queue (Stages 1–4).
- `PATCH /api/v1/queue/:id/stage` — Advance patient stage in queue.

### 13.4 Doctors & Schedules
- `GET  /api/v1/doctors` — List active doctors with department mappings.
- `POST /api/v1/doctors` — Add doctor profile (Admin only).
- `PUT  /api/v1/doctors/:id` — Update doctor profile.
- `GET  /api/v1/doctors/:id/slots` — Retrieve available time slots for a given date.
- `PUT  /api/v1/doctors/:id/schedules` — Configure day schedules and break hours.

### 13.5 Consultations
- `GET  /api/v1/consultations/:appointmentId` — Fetch consultation details (Rx, diagnoses, tests).
- `POST /api/v1/consultations/:appointmentId` — Save complete 4-step consultation transaction.

### 13.6 Medical Files & Storage
- `GET    /api/v1/files/patient/:patientId` — List all medical files for a patient.
- `POST   /api/v1/files/request-upload` — Validate permissions and issue signed S3 upload URL.
- `POST   /api/v1/files/confirm-upload` — Confirm upload completion and save metadata.
- `GET    /api/v1/files/:id/signed-url` — Authorize user and issue temporary 15-minute download URL.
- `PUT    /api/v1/files/:id` — Update file title, category, and tags (`can_edit_files`).
- `DELETE /api/v1/files/:id` — Delete file and remove object from storage (`can_delete_files`).

### 13.7 Beds & Wards
- `GET  /api/v1/beds` — Bed inventory with current occupancy and patient assignments.
- `POST /api/v1/beds` — Register new bed.
- `POST /api/v1/beds/admit` — Assign patient to bed.
- `POST /api/v1/beds/discharge` — Discharge patient from bed and sanitize.

### 13.8 Staff, Attendance & Permissions
- `GET   /api/v1/staff` — List hospital staff members.
- `POST  /api/v1/staff` — Register staff member (generates hashed credentials).
- `GET   /api/v1/attendance/daily` — Daily roster check-in statuses.
- `GET   /api/v1/attendance/monthly` — Monthly attendance matrix.
- `POST  /api/v1/attendance/selfie-verify` — Server-validated facial descriptor and GPS check-in.
- `GET   /api/v1/permissions/:staffId` — Retrieve active permission keys.
- `PUT   /api/v1/permissions/:staffId` — Update permission flags and account status.

### 13.9 BHOOMA AI Assistant
- `POST /api/v1/ai/chat` — Streaming chat endpoint via Server-Sent Events (SSE).
- `GET  /api/v1/ai/conversations` — Retrieve conversation history.
- `POST /api/v1/ai/confirm-action` — User confirmation of pending database mutations.
- `POST /api/v1/ai/cancel-action` — Cancel pending action.

---

# SECTION 14: BHOOMA AI MIGRATION & SAFETY PLAN

### 14.1 Elimination of Risky Dynamic SQL
The existing PHP implementation allowed the LLM to generate raw SQL strings that were executed against MySQL after passing regex checks. This is unsafe.

In the modernized architecture:
1. **Zero SQL Generation**: The LLM is **never** asked or permitted to write SQL statements.
2. **Structured Tool Calling / Function Execution**: The LLM is provided with strict JSON schemas representing read-only service functions:
   - `searchPatients({query: string})`
   - `getDoctorAvailability({doctorId: string, date: string})`
   - `getBedOccupancy({wardType: string})`
   - `getTodayAttendanceSummary()`
3. **Parameter Validation**: When the LLM decides to call a tool, NestJS parses the tool arguments through `class-validator` DTOs, executes the standard service method under the user's active tenant and permission scope, and returns structured JSON to the LLM context.

### 14.2 Human-in-the-Loop Mutation Gate
If the user asks the AI to perform a mutation (e.g. *"Admit patient Dev Patel to ICU-2"* or *"Cancel appointment #12"*):
1. The AI **cannot** execute the change directly.
2. It generates an `ai_pending_action` record storing the structured JSON payload.
3. The chat UI renders an **Interactive Action Card** displaying the exact parameters, before/after values, and two explicit buttons: `[Confirm & Execute]` and `[Cancel]`.
4. Only when the authorized human clicks `[Confirm]` does NestJS validate the user's permissions and commit the transaction.

### 14.3 Model Hosting & Inference Options
- **Development & Local Demonstrations**: Retain integration with local Ollama (`http://localhost:11434`, model `qwen2.5:3b` or `hms-ai`).
- **Cloud Staging / Production**: Utilize a serverless LLM provider with high throughput and low cost (e.g., Groq / Together AI running `Qwen-2.5-7B-Instruct` or `Llama-3.1-8B-Instant` at ~\$0.10–\$0.20 per million tokens) or proxy through a secure WireGuard tunnel to the hospital's local workstation.

---

# SECTION 15: PHASE-BY-PHASE IMPLEMENTATION ROADMAP

```mermaid
gantt
    title HMS Modernization Phase-by-Phase Timeline
    dateFormat  YYYY-MM-DD
    section Baseline & Foundations
    Phase 0 - Repository Audit & Baseline           :done,    p0, 2026-10-14, 3d
    Phase 1 - Architecture & Security Decisions     :active,  p1, after p0, 4d
    Phase 2 - PostgreSQL Schema & Backend Core      :         p2, after p1, 7d
    Phase 3 - Flutter App Shell & Design System     :         p3, after p2, 7d
    section Core Workflows
    Phase 4 - Auth, JWT & Granular RBAC             :         p4, after p3, 6d
    Phase 5 - Core Clinical Workflows (OPD/IPD/Rx)  :         p5, after p4, 10d
    Phase 6 - Medical Files & Private S3 Storage    :         p6, after p5, 6d
    Phase 7 - Beds, Staff, Biometrics & Operations  :         p7, after p6, 7d
    section Advanced & Release
    Phase 8 - QR Cards, Vector PDF & Safe AI        :         p8, after p7, 7d
    Phase 9 - Security Hardening & Perf Tests       :         p9, after p8, 5d
    Phase 10 - Cloud Staging Deployment             :         p10, after p9, 5d
    Phase 11 - Android APK Build & Testing          :         p11, after p10, 4d
    Phase 12 - Acceptance, Rollout & Runbook        :         p12, after p11, 4d
```

### Detailed Phase Specifications

#### Phase 0: Repository Audit & Baseline (Completed)
- **Objective**: Full code audit, vulnerability discovery, feature cataloging, and constraint mapping.
- **Deliverables**: Vulnerability register, baseline documentation, and feature preservation matrix.

#### Phase 1: Architecture & Technical Decisions
- **Objective**: Finalize tech stack specifications, provider contracts, and interface schemas.
- **Tasks**: Draft OpenAPI 3.0 specification for NestJS endpoints; create JSON schemas for AI function tools; finalize DTO structures.
- **Deliverables**: Architecture Decision Records (ADRs), Swagger API contract schema.

#### Phase 2: PostgreSQL Schema & Backend Core
- **Objective**: Establish the Supabase PostgreSQL database and NestJS boilerplate.
- **Tasks**:
  - Run SQL DDL migrations in Supabase.
  - Setup NestJS project with Prisma / TypeORM and `@nestjs/config`.
  - Implement global `ValidationPipe`, centralized `HttpExceptionFilter`, and Winston logging.
  - Implement tenant isolation middleware (`AsyncLocalStorage`).
- **Deliverables**: Runnable NestJS backend connected to Supabase PostgreSQL with health-check endpoints.

#### Phase 3: Flutter Shell & Design System
- **Objective**: Build cross-platform Flutter application foundation with responsive layout.
- **Tasks**:
  - Setup Flutter project configured for Web and Android.
  - Implement responsive scaffold (`ResponsiveLayout` with desktop sidebar and mobile drawer).
  - Build reusable UI component library: `AppleCard`, `StatusBadge`, `MetricCard`, `CustomDropdown`, `FloatingTextField`.
  - Setup `go_router` navigation and `flutter_riverpod` state management.
- **Deliverables**: Runnable Flutter Web and Android shells with theme preview and navigation shell.

#### Phase 4: Authentication, JWT & Granular RBAC
- **Objective**: Implement secure authentication and permission enforcement.
- **Tasks**:
  - Implement NestJS `AuthModule` with Argon2id password hashing and JWT issuance.
  - Implement `PermissionsGuard` and `@RequirePermission()` decorator.
  - Build Flutter `LoginScreen`, token persistence (`flutter_secure_storage`), and route guards.
- **Deliverables**: Working login, token refresh, and role-based route access.

#### Phase 5: Core Clinical Workflows
- **Objective**: Migrate patients, doctors, appointments, queue, and consultations.
- **Tasks**:
  - Implement NestJS modules: `PatientsModule`, `DoctorsModule`, `AppointmentsModule`, `ConsultationsModule`.
  - Build Flutter screens: `PatientDirectoryScreen`, `PatientRegistrationScreen`, `QueuePipelineScreen`, `ClinicalWorkstationScreen`.
  - Implement prescription frequency translator (`TID`, `BID`, `OD`).
- **Deliverables**: Complete clinical consultation loop from patient walk-in to discharge.

#### Phase 6: Medical Files & Private S3 Storage
- **Objective**: Implement file storage via private Supabase Storage buckets.
- **Tasks**:
  - Configure `medical-records` private bucket and RLS policies.
  - Implement NestJS pre-signed upload URL generator and confirmation endpoint.
  - Build Flutter `FileUploadDialog`, `MedicalGalleryScreen`, and `MedicalFileLightboxScreen`.
  - Implement audit logging interceptor for every file access.
- **Deliverables**: End-to-end medical file upload, preview, and audit tracking.

#### Phase 7: Beds, Staff, Biometrics & Operations
- **Objective**: Modernize operational hospital modules.
- **Tasks**:
  - Implement `BedsModule`, `StaffModule`, `AttendanceModule`, `ChargesModule`.
  - Build Flutter `BedWardMapScreen`, `StaffDirectoryScreen`, `AttendanceRosterScreen`.
  - Implement server-side Haversine geofence and biometric vector matching.
- **Deliverables**: Ward bed management and verified attendance tracking.

#### Phase 8: Advanced Modules (QR, PDF, Safe AI)
- **Objective**: Implement QR cards, vector prescription printing, and AI assistant.
- **Tasks**:
  - Integrate `mobile_scanner` in Flutter for instant QR scanning.
  - Build native vector PDF prescription generation using Dart `pdf` package.
  - Implement NestJS `AiModule` with function-calling tools and SSE streaming.
  - Build Flutter `AiChatDrawerWidget` and `AiActionReviewDialog`.
- **Deliverables**: QR workflows, vector PDF generation, and safe AI chatbot.

#### Phase 9: Security Hardening & Performance Testing
- **Objective**: Verify security defenses and load tolerances.
- **Tasks**:
  - Penetration testing for tenant isolation and permission bypass.
  - Load testing with k6 (simulating 50 concurrent doctors/staff).
  - Optimize database indexes and verify query execution plans.
- **Deliverables**: Security sign-off report and performance benchmark matrix.

#### Phase 10: Cloud Deployment (Vercel, Railway, Supabase)
- **Objective**: Deploy staging and production environments.
- **Tasks**:
  - Deploy NestJS API container to Railway with environment variables.
  - Deploy Flutter Web to Vercel with SPA rewrites.
  - Configure custom domains, TLS certificates, and CORS whitelisting.
- **Deliverables**: Live cloud staging URL accessible over HTTPS.

#### Phase 11: Android APK Build & Testing
- **Objective**: Compile, sign, and validate release Android APK.
- **Tasks**:
  - Configure Android package ID (`org.carepulse.hms`), app icon, and permissions.
  - Generate release keystore and configure `build.gradle.kts`.
  - Compile release APK (`flutter build apk --release --split-per-abi`).
  - Install on test Android tablet and phone; test camera QR, file uploads, and offline tolerance.
- **Deliverables**: Signed production APK and installation manual.

#### Phase 12: Acceptance, Rollout & Maintenance
- **Objective**: Hospital staff training and production transition.
- **Tasks**:
  - Conduct User Acceptance Testing (UAT) with hospital doctors and reception staff.
  - Populate initial master data (departments, doctors, beds, consultation charges).
  - Deliver administrator runbook and maintenance procedures.
- **Deliverables**: Signed UAT checklist and final handover.

---

# SECTION 16: VERCEL DEPLOYMENT PLAN (FLUTTER WEB)

### 16.1 Build Pipeline & Output
Flutter Web compiles into static assets (HTML, JavaScript, WebAssembly, and CanvasKit binaries). Vercel hosts these assets via global edge CDN.

1. **Compilation Command**:
   ```bash
   flutter build web --release --wasm --pwa-strategy=none
   ```
   *Output directory*: `build/web`

2. **Vercel Configuration (`vercel.json`)**:
   Create `vercel.json` in the root of the web project to handle client-side routing (SPA fallback) and security headers:
   ```json
   {
     "version": 2,
     "public": true,
     "cleanUrls": true,
     "rewrites": [
       { "source": "/(.*)", "destination": "/index.html" }
     ],
     "headers": [
       {
         "source": "/(.*)",
         "headers": [
           { "key": "X-Content-Type-Options", "value": "nosniff" },
           { "key": "X-Frame-Options", "value": "DENY" },
           { "key": "X-XSS-Protection", "value": "1; mode=block" },
           { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
         ]
       },
       {
         "source": "/assets/(.*)",
         "headers": [
           { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
         ]
       }
     ]
   }
   ```

3. **Environment Injection**:
   Client environment parameters are injected at build time using Dart defines:
   ```bash
   flutter build web --dart-define=API_BASE_URL=https://api.carepulse.org/api/v1 --dart-define=ENVIRONMENT=production
   ```
   *Rule*: **Never** inject Supabase service-role keys or database credentials into Flutter builds.

---

# SECTION 17: RAILWAY DEPLOYMENT PLAN (NESTJS BACKEND)

### 17.1 Production Containerization (`Dockerfile`)
```dockerfile
# Multi-stage Dockerfile for NestJS API
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm prune --production

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### 17.2 Railway Configuration & Environment Variables
- **Region**: Selected region matching database (e.g. AWS / GCP Asia South / Mumbai or nearest Railway location to minimize latency).
- **Restart Policy**: `ON_FAILURE` (Max retries: 10).
- **Health Check Endpoint**: `/api/v1/health` (Responds `200 OK` with database ping status).
- **Required Production Environment Variables**:
  ```env
  NODE_ENV=production
  PORT=3000
  DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:6543/postgres?pgbouncer=true
  DIRECT_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
  SUPABASE_URL=https://[REF].supabase.co
  SUPABASE_SERVICE_ROLE_KEY=eyJh...
  JWT_ACCESS_SECRET=[32-BYTE-RANDOM-HEX]
  JWT_REFRESH_SECRET=[32-BYTE-RANDOM-HEX]
  CORS_ORIGIN=https://app.carepulse.org,https://carepulse.vercel.app
  ```

---

# SECTION 18: SUPABASE CONFIGURATION PLAN

### 18.1 Project Setup & Region Selection
- **Organization & Region**: Select **AWS ap-south-1 (Mumbai, India)** to comply with data residency preferences and minimize latency to Indian hospital terminals (<30ms).
- **PostgreSQL Version**: 15+ with pgBouncer transaction pooling enabled on port `6543`.
- **Database Backup Policy**: Daily automated backups with 7-day Point-In-Time-Recovery (PITR) enabled on Supabase Pro plan.

### 18.2 Private Storage Bucket Security Policies
Execute in Supabase SQL Editor to enforce private access to `medical-records`:
```sql
-- Ensure bucket is private
INSERT INTO storage.buckets (id, name, public) 
VALUES ('medical-records', 'medical-records', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Disable public read access
CREATE POLICY "Deny Public Access" ON storage.objects
FOR ALL TO anon USING (false);

-- Allow NestJS backend service role full access
CREATE POLICY "Allow Backend Service Role" ON storage.objects
FOR ALL TO service_role USING (true) WITH CHECK (true);
```

---

# SECTION 19: ANDROID APK BUILD & DISTRIBUTION PLAN

### 19.1 Signing & Build Configuration
1. **Keystore Generation**:
   ```bash
   keytool -genkey -v -keystore carepulse-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias carepulse
   ```
2. **Key Properties (`android/key.properties`)**:
   ```properties
   storePassword=[SECURE_PASSWORD]
   keyPassword=[SECURE_PASSWORD]
   keyAlias=carepulse
   storeFile=../carepulse-release.jks
   ```
   *Security Note*: `key.properties` and `.jks` are added to `.gitignore`.

3. **Release Compilation**:
   ```bash
   flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://api.carepulse.org/api/v1
   ```
   Generates optimized APKs for `arm64-v8a` and `armeabi-v7a` (~18–25 MB each).

### 19.2 Safe Controlled Hospital Distribution
- **Initial Rollout**: Direct installation on hospital tablets and doctor phones via USB debugging or an authenticated in-house download portal (`https://app.carepulse.org/download/app-release.apk`).
- **Update Mechanism**: In-app version checker calling `GET /api/v1/app/version` on launch; alerts user when a mandatory update is available.
- **Google Play Store**: Future milestone using an internal testing track before public release.

---

# SECTION 20: MONTHLY CLOUD HOSTING COST ANALYSIS

Estimates reflect current official pricing (verified 2024/2025 standard cloud pricing) converted at an assumed exchange rate of **1 USD = 85.00 INR**.

### 20.1 Detailed Cost Breakdown by Workload Scenario

| Infrastructure Component | Scenario 1: Staging / Dev (Minimal) | Scenario 2: Small Hospital Production (Expected) | Scenario 3: Scaled Hospital Production (High Usage) |
|---|---|---|---|
| **Vercel Frontend** (Flutter Web) | **Hobby (Free)** — ₹0 | **Hobby / Pro (\$20)** — ₹1,700/mo | **Pro Plan (\$20)** — ₹1,700/mo |
| **Railway API Backend** (NestJS) | **Hobby (\$5)** — ₹425/mo | **Pro Tier Usage** (~512MB RAM, 0.5 CPU) — ~₹850/mo | **Pro Tier Usage** (~1GB RAM, 1.0 CPU) — ~₹1,700/mo |
| **Supabase PostgreSQL** | **Free Tier** — ₹0 | **Pro Plan (\$25)** (8GB DB, Daily Backups, No pause) — ₹2,125/mo | **Pro Plan + Compute Add-on** — ~₹3,400/mo |
| **Supabase Storage** (Medical Files) | Included in Free Tier (<1GB) | 100 GB Included in Pro; Extra 25GB/mo @ \$0.021/GB — ~₹150/mo | 300 GB Storage (~\$4.20 overage) — ~₹360/mo |
| **Data Egress Bandwidth** | Included (<2GB) | Included in Pro (250 GB/mo free) — ₹0 | 350 GB/mo (100GB overage @ \$0.09/GB) — ~₹765/mo |
| **AI LLM Inference** (Groq / Together)| Local Ollama / Free Tier — ₹0 | Cloud API (~10,000 queries/mo @ \$0.15/1M tokens) — ~₹250/mo | Cloud API (~50,000 queries/mo) — ~₹850/mo |
| **Total Estimated Monthly Cost (USD)**| **\$5.00 / month** | **~\$59.00 / month** | **~\$103.00 / month** |
| **Total Estimated Monthly Cost (INR)**| **~₹425 / month** | **~₹5,075 / month** | **~₹8,775 / month** |

### 20.2 Cost Optimization Notes
- **Supabase Free Tier Limitation**: The Free plan pauses projects after 7 days of inactivity and provides no point-in-time recovery. For any live clinical deployment, the **\$25 Pro Plan is mandatory**.
- **Bandwidth Shielding**: By serving thumbnail previews (`thumb_url`) in tables and galleries rather than full 10MB raw X-rays, storage egress bandwidth is reduced by over **85%**.

---

# SECTION 21: COMPREHENSIVE TESTING STRATEGY

### 21.1 Backend Test Architecture (NestJS)
- **Unit Tests (`Jest`)**:
  - Latin frequency translation functions (`TID` -> 3 times daily).
  - Haversine geofence calculation formula.
  - Facial vector distance matching algorithm.
- **Integration Tests (`Supertest` + Testcontainers PostgreSQL)**:
  - Complete appointment booking transaction with simulated concurrent requests to verify double-booking prevention.
  - Multi-hospital tenant isolation: Verifying that Hospital B credentials cannot read Hospital A records.
  - Permission enforcement: Testing that a staff member without `can_delete_files` receives `403 Forbidden`.

### 21.2 Flutter Test Architecture
- **Widget & Form Tests**:
  - `PatientRegistrationScreen` phone number validation (must be 10 digits).
  - `PrescriptionBuilderWidget` row addition and dosage validation.
  - Adaptive layout tests: Asserting that navigation drawer renders on mobile screen widths (<768px) and sidebar renders on desktop.

### 21.3 Security & Penetration Verification Checklist
- [ ] Attempting direct HTTP GET to private Supabase Storage bucket URLs returns `403 AccessDenied`.
- [ ] Submitting expired signed URLs returns `403 ExpiredToken`.
- [ ] Authenticated staff cannot escalate permissions or grant themselves `can_edit_patients`.
- [ ] SQL injection payloads in patient search strings are neutralized by parameterized queries.

---

# SECTION 22: BACKUP, RECOVERY & ROLLBACK STRATEGY

### 22.1 Cloud Backup Infrastructure
- **Automated Physical Backups**: Supabase Pro executes full daily backups via WAL-G with continuous write-ahead logging (WAL), providing **Point-In-Time Recovery (PITR)** to any second within the past 7 days.
- **Recovery Point Objective (RPO)**: **< 5 minutes** of data loss.
- **Recovery Time Objective (RTO)**: **< 30 minutes** to restore a secondary PostgreSQL database instance.

### 22.2 Release Rollback Procedures
- **Flutter Web (Vercel)**: Instant rollback to any prior Git deployment commit via one-click Vercel deployment restoration (<15 seconds).
- **NestJS API (Railway)**: Railway maintains prior deployment container images. Rolling back to a previous image takes <1 minute.
- **Database Migrations**: All migrations are written with reversible down-scripts (e.g. `V1__init.sql` and `U1__undo_init.sql`). Breaking schema changes follow the **Expand and Contract pattern**:
  1. *Expand*: Add new nullable column.
  2. Deploy application code supporting both schemas.
  3. Backfill data.
  4. *Contract*: Remove deprecated column after validation.

---

# SECTION 23: RISKS, ASSUMPTIONS & UNRESOLVED QUESTIONS

### 23.1 Technical Risks & Mitigations
1. **Network Interruptions in Hospital**:
   - *Risk*: Clinical consultations interrupted during hospital internet drops.
   - *Mitigation*: Flutter clinical workstation caches active prescription drafts in local SQLite/Hive storage, preventing lost doctor notes during momentary disconnections.
2. **Biometric Face Recognition Variability**:
   - *Risk*: Poor lighting or camera differences at hospital entrance causing attendance false negatives.
   - *Mitigation*: Fallback to manual check-in with supervisor approval logging (`marked_by: 'Supervisor'`).
3. **Telemedicine Video Requirements**:
   - *Risk*: Hospital may expect integrated video calling for "Online Consultations".
   - *Mitigation*: Clarify that the legacy system only handled digital prescription records and fee tracking. If real-time video is required, integrate WebRTC / Agora in Phase 8.

### 23.2 Open Decisions for Hospital Administration
- **Question 1**: Does the hospital have an existing Google Play Console account for public Android app release, or is direct APK distribution preferred initially?
- **Question 2**: For remote doctor access, should Multi-Factor Authentication (MFA via SMS or TOTP authenticator app) be mandatory for off-premise logins?

---

# SECTION 24: FINAL IMPLEMENTATION CHECKLIST

- [x] Repository audit completed and live credentials cataloged for rotation.
- [x] Feature preservation matrix mapped across all 27 modules.
- [x] Target PostgreSQL schema designed with strict typing, foreign keys, and indexes.
- [x] Medical file storage workflow transitioned from MySQL `LONGBLOB` to private S3 buckets.
- [x] Threat model and RBAC authorization architecture established.
- [x] Responsive Flutter UI design system and 35-screen catalog defined.
- [x] BHOOMA AI re-architected around safe tool calling with human-in-the-loop mutation gates.
- [x] Vercel, Railway, and Supabase deployment pipelines designed.
- [x] Monthly operating cost modeled across 3 realistic hospital workloads (~₹5,000/mo expected).
- [x] Multi-layer testing, backup, and release rollback procedures documented.

---

# SECTION 25: RECOMMENDED FIRST IMPLEMENTATION TASK

The immediate starting task for Phase 1/Phase 2 execution is:
1. **Credential Invalidation & Repository Cleansing**: Immediately rotate the exposed InfinityFree database password (`gDaughDyA4Dnmdw`) and remove active plain credentials from Git history.
2. **Database Initialization**: Spin up the target PostgreSQL instance on **Supabase** in AWS Mumbai (`ap-south-1`) and execute the initial DDL migration script provided in **Section 7.3** to create the new relational foundation.
3. **NestJS API Scaffold**: Initialize the NestJS backend repository with Prisma or TypeORM to establish the validated database connection and health-check endpoints.
