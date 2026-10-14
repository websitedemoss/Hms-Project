# CLOUD ARCHITECTURE & DEPLOYMENT PLAN: RAILWAY + SUPABASE
## Hospital Management System (HMS) Modernization

---

## 1. Executive Summary & Context
In accordance with the updated infrastructure mandate, the Hospital Management System is transitioning from local workstation hosting (`localhost:3000`, `localhost:5432`) to a **fully-managed, zero-hardware cloud topology**:
1. **Database & Object Storage**: **Supabase Cloud**
   - Managed PostgreSQL database in AWS (`aws-0-ap-southeast-2.pooler.supabase.com`).
   - Dual-connection architecture: Transaction Connection Pooler (port `6543`) for high-concurrency NestJS queries and Direct Session Connection (port `5432`) for Prisma schema migrations.
   - Private Supabase Storage bucket (`medical-files`) for clinical documents, lab scans, X-rays, and ICU monitor captures, accessed exclusively via 15-minute signed URLs.
2. **Backend Application API**: **Railway.app**
   - High-performance NestJS REST API container running in production.
   - Automated deployment pipeline with health checks (`/api/v1/health`) and auto-migrating startup commands (`npx prisma migrate deploy`).
   - Public HTTPS endpoint: `https://hms-project-production-8bd9.up.railway.app/api/v1`.
3. **Cross-Platform Frontend**: **Flutter Web & Android APK**
   - Single unified Dart codebase connecting directly to Railway over secure HTTPS.
   - Allows hospital staff to use Android tablets and phones across clinical wards and remotely without needing to be on a local Wi-Fi intranet.

---

## 2. Legacy State vs. Cloud Target: What Was Done & Why We Evolve

| Architectural Dimension | Legacy Implementation | Local Dev Baseline (Phases 1-3) | **Target Cloud Architecture (Railway + Supabase)** |
|---|---|---|---|
| **Server Hardware** | On-premise desktop running XAMPP | Developer laptop | **Zero physical server required; fully cloud-managed** |
| **Database Engine** | MySQL / MariaDB (unversioned tables) | Local PostgreSQL 18 service | **Supabase Cloud PostgreSQL (AWS Sydney)** |
| **Connection Pooling**| Single persistent MySQL connection | Direct Prisma connection pool | **Supabase Supavisor Pooler (port 6543, transaction mode)** |
| **Schema Migrations** | Dynamic `ALTER TABLE` in PHP scripts | `prisma migrate dev` locally | **Automated `npx prisma migrate deploy` in Railway container** |
| **Binary Medical Files**| `LONGBLOB` (up to 10MB inside DB) | Local filesystem paths | **Supabase Private Object Storage with 15-min signed URLs** |
| **API Availability** | Local intranet only | `localhost:3000` | **Public HTTPS on Railway (`*.up.railway.app`)** |
| **Android APK Access** | Inaccessible from outside network | Tethered to local subnet IP | **Global access over 4G/5G/Wi-Fi via Railway HTTPS** |

---

## 3. Gaps & What Needs to Be Improved for Cloud Resilience

1. **Connection Exhaustion on Serverless / PaaS**:
   - Multiple NestJS instances opening direct PostgreSQL connections can quickly exhaust database connection limits.
   - *Solution*: Route all NestJS query traffic through Supabase's Supavisor connection pooler (`port 6543`) using `pgbouncer=true&connection_limit=1`.
2. **Prisma Migration Compatibility with Connection Poolers**:
   - Prisma migrations require session-level locks and advisory locks that connection poolers in transaction mode do not support.
   - *Solution*: Utilize Prisma 6's dual-URL pattern: `url = env("DATABASE_URL")` (pooled) and `directUrl = env("DIRECT_URL")` (unpooled port 5432).
3. **Dynamic Port Binding**:
   - Cloud hosts like Railway assign dynamic `$PORT` environment variables rather than a fixed port `3000`.
   - *Solution*: Ensure NestJS bootstrap reads `process.env.PORT || 3000` and binds to `0.0.0.0`.
4. **Binary Medical File Decoupling**:
   - Storing large images in the database degrades database memory caching and slows down backups.
   - *Solution*: Implement Supabase Storage integration via `@supabase/supabase-js` where the database only stores metadata and `storage_path`, while binary files live in secure cloud buckets.

---

## 4. How We Make It Good (Core Cloud Architecture & Setup)

### A. Railway Backend Configuration
1. **Production Multi-Stage Dockerfile (`apps/backend/Dockerfile`)**:
   - Stage 1 (Builder): Installs OpenSSL and native build tools, compiles Prisma client, and builds NestJS TypeScript into `dist/`.
   - Stage 2 (Runner): Minimal `node:22-bookworm-slim` image containing only production dependencies, generated Prisma client, and compiled artifacts.
   - Startup command automatically executes pending database migrations before starting the API server:
     ```sh
     CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
     ```
2. **Railway Schema (`apps/backend/railway.json`)**:
   - Configures Dockerfile builder, sets healthcheck probe at `/api/v1/health` with 120s timeout, and sets `ON_FAILURE` auto-restart policy.

### B. Supabase Cloud Configuration
1. **Environment Variables**:
   - `DATABASE_URL`: `postgresql://postgres.[REF]:[PASS]@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1`
   - `DIRECT_URL`: `postgresql://postgres.[REF]:[PASS]@aws-0-ap-southeast-2.pooler.supabase.com:5432/postgres`
2. **Database Verification Status**:
   - Schema successfully migrated to Supabase.
   - Full master seed data executed against Supabase: Hospital (Medicare Hospital & I.C.U), 5 Departments, 4 Doctors with working day schedules and slots, 10 Inpatient Beds, 5 Consultation Charges, Geofence, AI Config, 4 Staff accounts (Argon2id hashes), and sample patients.

### C. Flutter Cross-Platform Configuration
1. **Dynamic Base URL Resolution (`AppConstants.apiBaseUrl`)**:
   - Default production endpoint points to Railway:
     `https://hms-project-production-8bd9.up.railway.app/api/v1`
   - Configurable at compile-time via `--dart-define=API_URL=...` or editable directly from the Flutter Settings screen.
   - Android APK release communicates cleanly over HTTPS with TLS 1.3 encryption.

---

## 5. What Makes It Great (Healthcare Resilience & Security)

1. **Zero Public Database Exposure**:
   - Supabase PostgreSQL requires SSL (`sslmode=require`) and can be restricted to Railway IP ranges or protected behind service credentials.
2. **15-Minute Ephemeral Medical File Access**:
   - When a doctor opens an X-ray or patient blood report, NestJS generates a temporary 15-minute signed URL from Supabase Storage. The raw storage URL is never permanent or public, protecting sensitive patient health information (PHI).
3. **Automated Audit Trail**:
   - Every read, download, or edit of a medical file is logged in the `file_audit_log` table with staff ID, timestamp, and client IP address.
4. **Zero Downtime Continuous Deployment**:
   - Pushing code to GitHub triggers Railway to build the Docker image, run Prisma migrations, verify the `/api/v1/health` check, and switch traffic seamlessly with zero hospital downtime.

---

## 6. Updated Phase-by-Phase Roadmap (Aligned to Railway + Supabase)

### Phase 1: Architecture & Technical Decisions ✅ [COMPLETED]
- Architectural decision records (ADRs) established.
- Target cloud stack defined (NestJS on Railway, Supabase PostgreSQL & Storage, Flutter Web & Android).

### Phase 2: PostgreSQL Schema & Backend Core Foundation ✅ [COMPLETED & SYNCED TO SUPABASE]
- 25 normalized models, foreign keys, cascade rules, and indexes.
- Verified live against Supabase Cloud PostgreSQL.
- Master hospital data seeded (Hospital, Departments, Doctors, Slots, Beds, Staff, Patients).
- NestJS core initialized with Global Exception Filters, Transform Interceptors, and Health Check endpoint.

### Phase 3: Flutter Shell & Clinical Design System ✅ [COMPLETED & APK GENERATED]
- Cross-platform Flutter client with Adaptive Shell (Desktop Sidebar vs Mobile Bottom Bar + Drawer).
- Clinical Design System with touch targets >= 48dp.
- 8 interactive module screens.
- Release APK generated (`apps/frontend/build/app/outputs/flutter-apk/app-release.apk`, 46.6 MB).

### Phase 4: Authentication, Authorization & User Sessions ⏳ [NEXT STEP]
- **NestJS Auth Module**: Dual-token JWT (`access_token` 15 min, `refresh_token` 7 days in database), Argon2id password verification.
- **Granular Permissions Guard**: Intercepting requests and checking against the 11 staff boolean permissions in Supabase.
- **Flutter Auth State & Secure Storage**: Login screen with session persistence and auto-refresh interceptor.
- **Railway Deployment**: First live cloud deployment of auth endpoints to Railway.

### Phase 5: Core Clinical Modules (API & UI Integration)
- Connect Patients, Appointments, Triage Queues, Beds, and Doctors to live Supabase endpoints via Railway.
- Live token assignment and triage stage progression (Scheduled -> Triage -> In Consultation -> Completed).

### Phase 6: Medical Files & Supabase Object Storage
- Initialize Supabase private bucket `medical-records`.
- Implement signed upload and download endpoints in NestJS.
- Replace legacy MySQL `LONGBLOB` with cloud object storage.
- File audit logging (`file_audit_log`).

### Phase 7: BHOOMA AI Clinical Assistant Integration
- Connect safe tool-calling engine with human-in-the-loop pending actions (`ai_pending_actions`).
- Deploy or proxy Ollama inference endpoints securely for clinical reasoning.

### Phase 8: Production Verification, Vercel Web Hosting & Final Distribution
- Deploy Flutter Web to Vercel (`https://hms-medicare.vercel.app`).
- Final verification of end-to-end cloud pipeline (Vercel Web + Railway API + Supabase Cloud + Android Release APK).
