# PHASE 1: ARCHITECTURE & TECHNICAL DECISIONS
## Hospital Management System (HMS) Modernization

---

## 1. Phase Objective & Overview
The objective of **Phase 1** is to lock in all fundamental architectural decisions, data boundaries, design patterns, and technology integrations before writing any backend or frontend application code. This phase ensures that the transition from the legacy PHP/MySQL monolith to **Flutter + NestJS + Supabase (PostgreSQL & Storage)** is robust, maintainable, secure, and compliant with healthcare data standards.

---

## 2. Legacy State Analysis: What Was Done (Current State)
In the existing PHP + MySQL application:
- **Architecture**: Monolithic script-based backend (`*.php` files in root and `api/`), tightly coupled with server-rendered HTML, inline JavaScript, and direct MySQL queries using `mysqli`.
- **API Style**: Ad-hoc query-string-based dispatching (`api/patients.php?action=get_all`, `api/booking.php?action=book`), with inconsistent HTTP method semantics (some state-modifying actions use `GET`, while others use `POST`).
- **Data Persistence**: Unversioned MySQL tables auto-created on runtime via `CREATE TABLE IF NOT EXISTS` and `ALTER TABLE ADD COLUMN` inside `db.php` upon application startup.
- **Binary Data**: Stored directly as `LONGBLOB` fields in the `patient_files` table, severely inflating database backups and database memory cache usage.
- **Authentication & Sessions**: PHP file-based `$_SESSION` cookies tied to an Apache web server, preventing stateless cross-origin API calls or reliable mobile Android app usage.
- **Permissions**: Custom table `staff_permissions` evaluated via procedural helper functions (`checkStaffPermission`), but with plaintext passwords exposed in the database (`plain_password` column).
- **AI Integration**: Experimental local LLM pipeline executing dynamic raw SQL queries against MySQL based on regular expression checks (`ai/sql_sanitizer.php`).

---

## 3. Gaps & What Needs to Be Improved
1. **Security & Data Exposure**:
   - Live database credentials for InfinityFree committed to Git (`db.php`).
   - Plaintext passwords stored in the database for staff accounts.
   - Reliance on client assertions for geofencing and facial recognition (`face_verified: 1`).
2. **Database Integrity & Concurrency**:
   - Absence of strict foreign key cascades on several tables.
   - Race conditions during peak appointment booking hours (risk of doctor double-booking).
   - Incomplete hospital tenant isolation (queries falling back to `WHERE (hospital_id = ? OR hospital_id IS NULL)`).
3. **Application Decoupling**:
   - Frontend and backend code are interwoven; PHP scripts echo JSON or HTML depending on request parameters.
   - Flutter cannot consume legacy PHP session endpoints without complex cookie jar management.
4. **File Storage Bottlenecks**:
   - Up to 10MB binary scans stored directly in database rows, creating multi-gigabyte table dumps and blocking web requests during GD library thumbnail generation.
5. **AI Safety**:
   - Unrestricted SQL generation by LLMs poses prompt injection risks and potential data leakage.

---

## 4. How We Make It Good (Target Core Architecture)
To resolve these deficiencies systematically, the core architecture establishes:
- **Clean Backend Boundary (NestJS)**: A typed TypeScript backend with modular architecture (`AuthModule`, `PatientsModule`, `AppointmentsModule`, `ConsultationsModule`, `FilesModule`, `AiModule`).
- **Standardized REST API**: Versioned endpoints under `/api/v1` adhering strictly to HTTP verbs (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) with unified JSON response envelopes and OpenAPI 3.0 / Swagger documentation.
- **Relational PostgreSQL Foundation**: 21 clean tables hosted on Supabase in AWS Mumbai (`ap-south-1`), using typed columns (`TIMESTAMPTZ`, `UUID`, `INT GENERATED ALWAYS AS IDENTITY`), strict foreign keys, and indexes.
- **Private Object Storage**: Migration of medical files out of the database into private Supabase Storage buckets, using 15-minute temporary signed URLs.
- **Stateless Dual-Token JWT**: Short-lived Access Tokens (15 min) + secure Refresh Tokens (7 days) with family rotation.
- **Shared Flutter Client**: A unified codebase for Flutter Web (hospital desktop terminals) and Flutter Android (mobile rounds and QR scanning) with responsive layouts.

---

## 5. What Makes It Great (Enterprise & Healthcare Polish)
To elevate this project from an ordinary refactor to an enterprise-grade hospital platform:
1. **Zero-Trust Multi-Tenancy**: Every request context dynamically resolves `hospital_id` via NestJS `AsyncLocalStorage` and enforces tenant isolation at both the ORM level and PostgreSQL Row-Level Security (RLS) policies.
2. **Safe Tool-Calling AI Architecture**: BHOOMA AI never writes SQL. It interacts with the hospital system exclusively through validated NestJS service methods with strict input schemas and **Human-in-the-Loop Confirmation Cards** for database mutations.
3. **Server-Validated Biometrics & GPS**: Attendance requests recalculate Haversine distance from coordinates and compute Euclidean distance across 128-float face embeddings on the backend.
4. **Resilient Offline Triage Caching**: Flutter clinical workstations cache active consultation drafts locally, preventing data loss if hospital Wi-Fi fluctuates during patient rounds.
5. **High-Definition Vector PDF Prescriptions**: Vector-based rendering with printable prescription slip layouts, replacing fuzzy HTML-to-canvas screenshots.

---

## 6. Architecture Decision Records (ADRs)

### ADR-01: Repository Organization (Unified Monorepo)
- **Status**: Accepted
- **Context**: We need to manage both the Flutter multi-platform frontend and the NestJS backend while keeping documentation and configuration synchronized.
- **Decision**: Adopt a clean **Monorepo** structure within `c:\DATA\Stuff\Project\SEM-9`:
  ```text
  c:\DATA\Stuff\Project\SEM-9\
  ├── apps/
  │   ├── frontend/         # Flutter application (Web & Android)
  │   └── backend/          # NestJS application (TypeScript)
  ├── docs/                 # Phase-by-phase engineering specifications
  ├── packages/             # Shared assets / API contracts (optional)
  └── legacy/               # Preserved original PHP & MySQL codebase
  ```
- **Rationale**: Keeps full-stack feature implementations unified per phase, avoids multi-repo synchronization friction, and allows single-command CI/CD orchestration.

---

### ADR-02: Backend Framework & API Style (NestJS REST API)
- **Status**: Accepted
- **Context**: The backend must handle authentication, granular permissions, transactions, medical file signed URLs, and AI streaming.
- **Decision**: Build a modular **NestJS** monolith using TypeScript and RESTful conventions (`/api/v1`).
- **Rationale**:
  - Out-of-the-box support for dependency injection, guards, interceptors, and pipes.
  - Native validation using `class-validator` and `class-transformer` DTOs.
  - Auto-generated OpenAPI / Swagger documentation (`/api/docs`) allowing client code generation.
  - Server-Sent Events (SSE) support for BHOOMA AI streaming chat.

---

### ADR-03: ORM & Database Layer (Prisma ORM with Local PostgreSQL/Docker -> Supabase Transition)
- **Status**: Accepted (User Confirmed)
- **Context**: We need a type-safe database layer that prevents SQL injection and handles migrations reliably, with the capability to run locally during development before connecting to managed Supabase in the cloud.
- **Decision**: Use **Prisma ORM** targeting a **local PostgreSQL instance / Docker container for initial development**, designed with direct compatibility for migration to **Supabase Cloud (AWS Mumbai)** for staging and production:
  - Development: Local PostgreSQL instance on port `5432` (`postgresql://postgres:postgres@localhost:5432/hospital_db`).
  - Staging/Production: Supabase connection pooling via `DATABASE_URL` (port 6543) and direct connection for migrations via `DIRECT_URL` (port 5432).
- **Rationale**:
  - Declarative schema (`schema.prisma`) that generates fully typed TypeScript clients.
  - Zero cloud dependency or latency during local Phase 2 development.
  - Seamless migration between local PostgreSQL and Supabase PostgreSQL with zero schema changes.
  - Built-in migration tracking (`prisma migrate dev / deploy`).
  - Eliminates hand-crafted SQL strings and prevents SQL injection vulnerabilities.

---

### ADR-04: Flutter State Management & Routing (Riverpod + GoRouter)
- **Status**: Accepted
- **Context**: The Flutter application must run seamlessly on desktop browsers (Web) and mobile tablets/phones (Android), sharing models, repositories, and state.
- **Decision**: Use **Riverpod 2.x (with code generation)** for reactive state management and **GoRouter** for declarative routing.
- **Rationale**:
  - Compile-time safety with zero runtime `ProviderNotFoundException`.
  - Excellent support for caching, auto-dispose, and asynchronous data flows (`AsyncValue`).
  - `GoRouter` handles browser URL synchronization, forward/back buttons, and route guards (redirecting unauthenticated users to `/login`).

---

### ADR-05: Identity, Authentication & Permissions (Dual-Token JWT + Granular RBAC)
- **Status**: Accepted
- **Context**: The system must support hospital staff with 11 granular permissions, hospital administrators, and secure remote logins.
- **Decision**: Implement NestJS-managed **Dual-Token JWT** (Access Token: 15 min, Refresh Token: 7 days) combined with Argon2id password hashing:
  - Access tokens contain staff ID, hospital ID, role, and active permission keys.
  - Refresh tokens are stored in the database with family tracking to detect replay attacks.
  - Granular permissions are checked via a NestJS `@RequirePermission('can_upload')` guard on each endpoint.
- **Rationale**: Replaces insecure PHP sessions, eliminates cleartext password storage, and enables seamless token refresh on both Flutter Web and Android.

---

### ADR-06: Medical File Storage Architecture (Private Supabase Storage)
- **Status**: Accepted
- **Context**: Medical files (X-rays, blood reports, PDFs) are currently stored as `LONGBLOB`s in MySQL.
- **Decision**: Use private **Supabase Storage** with pre-signed URLs:
  - Bucket: `medical-records` (Visibility: Private).
  - Storage path: `hosp_{hospital_id}/pat_{patient_id}/{year}/{uuid}_{filename}`.
  - Upload: Flutter requests a signed upload URL from NestJS, uploads directly to Supabase S3, and confirms completion to NestJS to create metadata.
  - Download / View: NestJS validates user permissions, logs an audit entry, and issues a 15-minute signed URL.
- **Rationale**: Reduces database size, decreases memory bloat, leverages global CDN caching, and guarantees private, auditable file access.

---

### ADR-07: BHOOMA AI Integration Architecture (Safe Tool Calling)
- **Status**: Accepted
- **Context**: The legacy chatbot executed dynamic raw SQL generated by Ollama, creating high risk for SQL injection and hallucinations.
- **Decision**: Re-architect BHOOMA AI to use **Structured Tool Calling**:
  - The LLM cannot write raw SQL.
  - The LLM receives structured tool schemas (e.g., `searchPatients`, `getDoctorSchedule`, `getBedAvailability`).
  - Read-only tools execute standard NestJS services and return structured JSON.
  - Any mutation (e.g. create appointment, admit bed) creates an `ai_pending_action` record and displays an interactive confirmation card in the chat UI.
- **Rationale**: Completely eliminates SQL injection, guarantees multi-tenant isolation, and ensures human clinical oversight before data is modified.

---

### ADR-08: Hosting Topology & Data Residency
- **Status**: Accepted
- **Context**: The hospital has no on-premise physical server and requires cloud hosting with low latency and compliance with Indian healthcare regulations (DPDPA 2023).
- **Decision**:
  - **Flutter Web**: Deployed on **Vercel** Edge static hosting with SPA rewrites.
  - **NestJS API**: Deployed on **Railway** container service (Node.js 20 LTS).
  - **PostgreSQL & Storage**: Hosted on **Supabase** in **AWS Mumbai (ap-south-1)**.
- **Rationale**: Ensures sub-30ms database latency for Indian terminals, adheres to Indian data residency preferences, provides 99.9% uptime, and keeps monthly infrastructure costs under ~₹5,000/month.

---

### ADR-09: Telemedicine / Online Consultation Roadmap
- **Status**: Accepted
- **Context**: The legacy system provides digital consultation record-keeping, prescription notes, and fee collection, but no live video calling.
- **Decision**:
  - **Phase 5 & 8**: Retain and modernize the existing digital clinical record workflow (notes, diagnoses, prescription attachments, and billing).
  - **Future Extension**: Design the data schema to support external WebRTC / Agora video room IDs when the hospital chooses to enable live video calling.
- **Rationale**: Avoids unnecessary third-party subscription costs (WebRTC infrastructure) until the hospital explicitly requests live video calling.

---

### ADR-10: Android Distribution Strategy
- **Status**: Accepted
- **Context**: The Android application is intended for hospital tablets, nurses, and doctors.
- **Decision**:
  - **Initial Release**: Sign release APKs using Android Keystore and distribute via direct authenticated download from the hospital portal (`/download/app-release.apk`) with an in-app update checker.
  - **Secondary Track**: Prepare app bundle (`.aab`) for Google Play Store Internal Testing track once the hospital sets up a Google Play Console account.
- **Rationale**: Allows immediate on-device testing and deployment on hospital tablets without waiting for app store review delays.

---

## 7. Phase 1 Definition of Done (DoD)
- [x] All 10 Architecture Decision Records (ADRs) documented and approved.
- [x] Monorepo directory structure created.
- [x] Target tech stack locked: Flutter (Web & Android) + NestJS + Prisma + Supabase (PostgreSQL & Storage).
- [x] Security plan verified: Dual-token JWT, Argon2id hashing, 11 granular permissions, private S3 buckets.
- [x] AI safety boundary established: Structured tool calling with zero raw SQL execution.

**Next Phase**: Proceed to **Phase 2 — PostgreSQL Schema & Backend Core** (Setting up Supabase migrations and initializing the NestJS backend project).
