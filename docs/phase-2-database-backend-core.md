# PHASE 2: POSTGRESQL SCHEMA & BACKEND CORE FOUNDATION
## Hospital Management System (HMS) Modernization

---

## 1. Phase Objective & Overview
The objective of **Phase 2** is to establish the complete relational database architecture and the backend application runtime foundation. We transition from fragile, unversioned MySQL scripts to a strongly-typed **PostgreSQL 18** schema managed via **Prisma ORM**, and initialize the modular **NestJS** application framework in `apps/backend/`.

At the completion of Phase 2, the system will have:
1. A live, running PostgreSQL database (`hospital_db`) with all 21 normalized models, primary/foreign keys, indexes, and enums.
2. An automated Prisma migration pipeline (`prisma migrate dev`).
3. A complete hospital master seed script (`prisma/seed.ts`).
4. An initialized, runnable NestJS project configured with TypeScript, global validation, centralized error handling, structured logging, and health-check monitoring (`/api/v1/health`).

---

## 2. Legacy State Analysis: What Was Done (Current State)
In the existing PHP + MySQL application:
- **Schema Management**: Handled dynamically at runtime in [`db.php`](file:///c:/DATA/Stuff/Project/SEM-9/db.php#L59-L250) using `SHOW COLUMNS` and `ALTER TABLE ADD COLUMN` commands executed on every page reload.
- **Data Integrity**: Missing foreign key constraints across multiple tables (e.g. `doctor_categories`, `patient_files`, `timeline_events` relied on soft references).
- **Binary File Storage**: Medical images (X-rays, lab scans, PDF reports) were stored directly in the `patient_files.file_data` column as `LONGBLOB`s up to 10MB each.
- **Request Validation**: Zero schema validation before database execution. Endpoints parsed untyped `$_POST` or `file_get_contents('php://input')` directly (e.g., in [`api/patients.php`](file:///c:/DATA/Stuff/Project/SEM-9/api/patients.php#L204)).
- **Error Handling**: Ad-hoc `try/catch` or plain `echo json_encode(['status' => 'error'])`, with unhandled PHP warnings leaking sensitive file paths into responses.

---

## 3. Gaps & What Needs to Be Improved
1. **Unversioned Database Schema**:
   - Changes were made arbitrarily in `.sql` files (`schema.sql`, `hospital_update.sql`, `hospital_db_dump.sql`) with no single source of truth or migration history.
2. **Database Performance Drag**:
   - `LONGBLOB` file data severely inflated table disk footprint, slowed down database backups, and polluted RAM buffer pools.
3. **Missing Concurrency Controls**:
   - No row-level locking or serializable transactions when reserving doctor appointment slots or assigning beds, creating double-booking race conditions under load.
4. **Untyped API Payloads**:
   - Missing input sanitization and type enforcement allowed invalid strings, missing required parameters, or SQL injection vectors.
5. **No Structured Observability**:
   - No request tracing, centralized logging, or health check endpoints for container monitoring.

---

## 4. How We Make It Good (Core Technical Execution)
To build a production-grade backend engine:
- **Prisma Declarative Schema (`schema.prisma`)**:
  - Defines all 21 models with strict typing, foreign keys, cascade rules, and indexes.
  - Automatically generates fully typed TypeScript database clients (`@prisma/client`).
- **Clean Relational Schema in PostgreSQL 18**:
  - `INT GENERATED ALWAYS AS IDENTITY` for high-performance internal keys.
  - Native `UUID` for public security tokens (`qr_token`).
  - Native `TIMESTAMPTZ`, `DATE`, and `TIME` types replacing loose strings.
  - Enum types for statuses (`AppointmentStatus`, `BedStatus`, `StaffStatus`, etc.).
- **Modular NestJS Architecture**:
  ```text
  apps/backend/src/
  ├── common/
  │   ├── filters/http-exception.filter.ts     # Standardized JSON error response envelope
  │   ├── interceptors/logging.interceptor.ts  # Performance & request audit logging
  │   ├── interceptors/transform.interceptor.ts# Standardized { success, data, meta } envelope
  │   └── pipes/validation.pipe.ts             # class-validator whitelist & transform
  ├── config/                                  # Environment variables schema validation
  ├── modules/
  │   ├── prisma/                              # PrismaService with shutdown hooks
  │   └── health/                              # Terminus health checks (DB ping & memory)
  ├── app.module.ts
  └── main.ts                                  # App bootstrap with CORS, helmet & global pipes
  ```
- **Connection Configuration**:
  - Configured via `.env` pointing to local PostgreSQL: `postgresql://postgres:kishan12@localhost:5432/hospital_db?schema=public`.
  - Seamlessly portable to Supabase cloud connection pooling (`pgbouncer=true`) for staging and production.

---

## 5. What Makes It Great (Enterprise & Healthcare Polish)
1. **Atomic Database Seeding (`prisma/seed.ts`)**:
   - Pre-populates clean clinical master data:
     - 5 Hospital Departments (Cardiology, Orthopaedics, Paediatrics, Neurology, General Medicine).
     - 4 Doctors with working day schedules and interval time slots.
     - 10 Hospital Beds across ICU and General Wards.
     - Master Consultation Charges (OPD ₹200, Specialist ₹800, Online ₹500).
     - Default Super Admin account (`admin`) with an **Argon2id** password hash.
     - Verified Staff Accounts with active permissions.
2. **Unified Response & Error Envelopes**:
   Every response follows a strict, predictable JSON structure:
   ```json
   // Success
   {
     "success": true,
     "statusCode": 200,
     "data": { ... },
     "meta": { "timestamp": "2026-10-13T18:00:00Z" }
   }

   // Error
   {
     "success": false,
     "statusCode": 400,
     "error": "Bad Request",
     "message": ["phone must be a valid 10-digit number"],
     "timestamp": "2026-10-13T18:00:00Z",
     "path": "/api/v1/patients"
   }
   ```
3. **Database Performance Indexing**:
   - Multi-column composite indexes on high-frequency queries:
     - `appointments(hospital_id, date, slot)`
     - `staff_attendance(hospital_id, date)`
     - `patient_files(hospital_id, patient_id)`
4. **Prepared for Supabase S3**:
   - `patient_files` contains `storage_path VARCHAR(500)` instead of `LONGBLOB`. Binary data is completely decoupled from database tables.

---

## 6. Complete Database Model Inventory (Prisma Schema)

| Model Name | Table Name | Purpose | Primary Key | Key Relations & Constraints |
|---|---|---|---|---|
| `Hospital` | `hospitals` | Multi-hospital tenancy anchor | `id` (Int Identity) | 1-to-many with Patients, Doctors, Staff, Beds |
| `Department` | `departments` | Clinical hospital departments | `id` (String) | Belongs to Hospital, 1-to-many with Doctors |
| `Doctor` | `doctors` | Medical practitioners directory | `id` (String) | Belongs to Hospital & Department, has Schedules |
| `DoctorCategory`| `doctor_categories` | Many-to-many doctor specialties | `(doctorId, departmentId)` | Composite PK |
| `DoctorDaySchedule`| `doctor_day_schedules`| Per-day working hours & breaks | `id` (Int Identity) | Unique on `(doctorId, dayOfWeek)` |
| `DoctorSlot` | `doctor_slots` | Explicit booking time slots | `id` (Int Identity) | Belongs to Doctor |
| `Patient` | `patients` | Patient directory & demographics | `id` (String MRN) | Unique `qr_token` (UUID), belongs to Hospital |
| `Bed` | `beds` | Inpatient bed inventory | `id` (String) | Unique `(hospitalId, bedNumber)` |
| `Appointment` | `appointments` | Bookings & triage pipeline | `id` (Int Identity) | Belongs to Patient, Doctor, Hospital |
| `Diagnosis` | `diagnoses` | Clinical consultation diagnoses | `id` (Int Identity) | Belongs to Appointment (Cascade Delete) |
| `Prescription` | `prescriptions` | Medicine dosage & instructions | `id` (Int Identity) | Belongs to Appointment (Cascade Delete) |
| `TimelineEvent`| `timeline_events` | Patient visit activity log | `id` (Int Identity) | Belongs to Patient & Appointment |
| `PatientFile` | `patient_files` | Medical file metadata & storage key | `id` (Int Identity) | Decoupled S3 path, belongs to Patient |
| `FileAuditLog` | `file_audit_log` | Medical file access audit trail | `id` (Int Identity) | Belongs to Hospital & Patient |
| `Staff` | `staff` | Staff directory & credentials | `id` (Int Identity) | Unique `(hospitalId, staffCode)`, unique `username` |
| `StaffPermission`| `staff_permissions` | 11 granular permission keys | `id` (Int Identity) | Unique `(staffId, permissionKey)` |
| `HospitalGeofence`| `hospital_geofence` | GPS attendance boundary | `id` (Int Identity) | Belongs to Hospital |
| `StaffAttendance`| `staff_attendance` | Daily attendance & biometric logs| `id` (Int Identity) | Unique `(staffId, date)` |
| `ConsultationCharge`| `consultation_charges`| Service charge pricing matrix | `id` (Int Identity) | Belongs to Hospital |
| `OnlineConsultation`| `online_consultations`| Remote consultation records | `id` (Int Identity) | Belongs to Patient, Doctor, Hospital |
| `AiConfig` | `ai_config` | AI model & inference settings | `id` (Int Identity) | Unique per Hospital |
| `AiConversation`| `ai_conversations` | AI chat session records | `id` (Int Identity) | Belongs to Hospital |
| `AiChatMessage`| `ai_chat_messages` | Multi-turn chat message logs | `id` (Int Identity) | Belongs to AiConversation |
| `AiPendingAction`| `ai_pending_actions`| Human confirmation action gate | `id` (Int Identity) | Belongs to AiConversation |
| `AiActionLog` | `ai_action_log` | Audit log of executed AI tools | `id` (Int Identity) | Belongs to Hospital |

---

## 7. Phase 2 Implementation Steps & Checklist

- [x] Local PostgreSQL database `hospital_db` created and connectivity verified on `localhost:5432`.
- [x] Initialize NestJS backend application in `apps/backend/`.
- [x] Install Prisma ORM (`prisma`, `@prisma/client`) and configure connection string.
- [x] Write declarative `prisma/schema.prisma` covering all 25 models.
- [x] Execute initial database migration (`npx prisma migrate dev --name init`).
- [x] Write and execute hospital seed script (`prisma/seed.ts`).
- [x] Implement NestJS `PrismaModule` and `PrismaService` with connection lifecycle.
- [x] Configure global validation pipes, standardized exception filters, and request transform interceptors.
- [x] Implement Health Check endpoint (`GET /api/v1/health`) and OpenAPI Swagger documentation (`/api/docs`).
- [x] Verify NestJS build (`npm run build`) and start server on port `3000`.

---

## 8. Verification & Test Evidence

### A. Prisma Migration & Seed
- **Migration**: Applied `20261013123348_init` generating all 25 PostgreSQL tables, primary keys, foreign key constraints, and performance indexes in `hospital_db`.
- **Seeded Data**:
  - Hospital: `Medicare Hospital & I.C.U` (ID: 1)
  - 5 Clinical Departments: Cardiology, Neurology, Orthopedics, General Medicine, Pediatrics
  - 4 Doctors: With working day schedules, 30-minute interval slots, and specialty department mappings
  - 10 Beds: ICU-01 to ICU-04, General Ward GEN-01 to GEN-04, Private Wing PVT-01 to PVT-02
  - 5 Consultation Charges: OPD, Specialist, Super-Specialist, Emergency, Follow-up
  - Geofence: 250m circular perimeter centered on campus coordinates (23.0225° N, 72.5714° E)
  - BHOOMA AI Config: Ollama provider, `qwen2.5:3b`, max tokens 2048
  - Staff Accounts: 4 users (`admin`, `dr.rajesh`, `reception`, `nurse.sunita`) with Argon2id hashed passwords and all 11 granular boolean permissions populated
  - Sample Patients: `CP-2026-001` (Ramesh Patel) and `CP-2026-002` (Meena Shah) with appointments, ICD-10 diagnoses, and prescriptions

### B. Live Health Check Endpoint (`GET /api/v1/health`)
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "status": "ok",
    "timestamp": "2026-10-13T12:39:35.003Z",
    "uptimeSeconds": 55,
    "database": {
      "status": "connected",
      "latencyMs": 7,
      "hospitalsRegistered": 1,
      "error": null
    },
    "environment": "development",
    "version": "1.0.0"
  }
}
```

### C. Standardized Error Handling Test (`GET /api/v1/invalid-route`)
```json
{
  "success": false,
  "statusCode": 404,
  "timestamp": "2026-10-13T12:39:56.270Z",
  "path": "/api/v1/invalid-route",
  "message": "Cannot GET /api/v1/invalid-route",
  "error": "Not Found"
}
```

### D. Swagger / OpenAPI Documentation
- Accessible live at `http://localhost:3000/api/docs` returning `HTTP/1.1 200 OK`.

---

**Phase 2 Status**: **COMPLETE & VERIFIED**
**Next Phase**: Proceed to **Phase 3 — Flutter Shell & Design System** (Building the responsive multi-platform frontend shell for Web and Android).
