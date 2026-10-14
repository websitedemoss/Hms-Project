-- CreateTable
CREATE TABLE "hospitals" (
    "id" SERIAL NOT NULL,
    "hospital_code" VARCHAR(20) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "tagline" VARCHAR(255) DEFAULT 'Medicare Hospital & I.C.U',
    "phone" VARCHAR(30),
    "email" VARCHAR(150),
    "address" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "hospitals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "departments" (
    "id" VARCHAR(100) NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "icon" VARCHAR(60) DEFAULT 'fa-hospital',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "departments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "doctors" (
    "id" VARCHAR(50) NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "department_id" VARCHAR(100),
    "phone" VARCHAR(50),
    "degree" VARCHAR(150),
    "experience" VARCHAR(50),
    "consultation_fee" DECIMAL(10,2) NOT NULL DEFAULT 500.00,
    "status" VARCHAR(30) NOT NULL DEFAULT 'Available',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "doctors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "doctor_categories" (
    "doctor_id" VARCHAR(50) NOT NULL,
    "department_id" VARCHAR(100) NOT NULL,

    CONSTRAINT "doctor_categories_pkey" PRIMARY KEY ("doctor_id","department_id")
);

-- CreateTable
CREATE TABLE "doctor_day_schedules" (
    "id" SERIAL NOT NULL,
    "doctor_id" VARCHAR(50) NOT NULL,
    "day_of_week" VARCHAR(20) NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "start_time" VARCHAR(20) NOT NULL DEFAULT '09:00 AM',
    "end_time" VARCHAR(20) NOT NULL DEFAULT '05:00 PM',
    "duration_minutes" INTEGER NOT NULL DEFAULT 30,
    "break_start" VARCHAR(20),
    "break_end" VARCHAR(20),
    "custom_slots" JSONB DEFAULT '[]',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "doctor_day_schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "doctor_slots" (
    "id" SERIAL NOT NULL,
    "doctor_id" VARCHAR(50) NOT NULL,
    "time_slot" VARCHAR(30) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "doctor_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patients" (
    "id" VARCHAR(50) NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "surname" VARCHAR(100) NOT NULL,
    "father_name" VARCHAR(100),
    "phone" VARCHAR(30),
    "age" INTEGER,
    "gender" VARCHAR(20),
    "blood_group" VARCHAR(10),
    "emergency_contact_name" VARCHAR(150),
    "emergency_contact_phone" VARCHAR(30),
    "qr_token" UUID NOT NULL,
    "qr_generated_at" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "patients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "beds" (
    "id" VARCHAR(50) NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "bed_number" VARCHAR(50) NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "wing" VARCHAR(100) DEFAULT 'Main Ward',
    "status" VARCHAR(30) NOT NULL DEFAULT 'Available',
    "patient_id" VARCHAR(50),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "beds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appointments" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "patient_id" VARCHAR(50) NOT NULL,
    "doctor_id" VARCHAR(50) NOT NULL,
    "type" VARCHAR(100) DEFAULT 'General Consultation',
    "date" DATE NOT NULL,
    "slot" VARCHAR(30) NOT NULL,
    "token_number" INTEGER,
    "token_assigned_at" TIMESTAMPTZ,
    "token_assigned_by" INTEGER,
    "symptoms" TEXT,
    "allergies" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'Scheduled',
    "stage" INTEGER NOT NULL DEFAULT 1,
    "bed_number" VARCHAR(50),
    "doctor_notes" TEXT,
    "booking_type" VARCHAR(30) NOT NULL DEFAULT 'walk-in',
    "booking_ref" VARCHAR(50),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "appointments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "diagnoses" (
    "id" SERIAL NOT NULL,
    "appointment_id" INTEGER NOT NULL,
    "icd10_code" VARCHAR(20),
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "diagnoses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prescriptions" (
    "id" SERIAL NOT NULL,
    "appointment_id" INTEGER NOT NULL,
    "medicine_name" VARCHAR(255) NOT NULL,
    "dosage" VARCHAR(100) NOT NULL,
    "frequency" VARCHAR(100) NOT NULL,
    "duration" VARCHAR(100) NOT NULL,
    "instructions" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "prescriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "timeline_events" (
    "id" SERIAL NOT NULL,
    "appointment_id" INTEGER,
    "patient_id" VARCHAR(50) NOT NULL,
    "event_time" VARCHAR(50) NOT NULL,
    "event_description" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "timeline_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_files" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "patient_id" VARCHAR(50) NOT NULL,
    "appointment_id" INTEGER,
    "title" VARCHAR(255) NOT NULL,
    "category" VARCHAR(60) NOT NULL DEFAULT 'Other',
    "highlight" VARCHAR(255),
    "description" TEXT,
    "storage_path" VARCHAR(500) NOT NULL,
    "thumbnail_path" VARCHAR(500),
    "mime_type" VARCHAR(100) NOT NULL,
    "file_size_bytes" BIGINT NOT NULL,
    "tags" VARCHAR(500),
    "uploaded_by_id" INTEGER,
    "uploaded_by_name" VARCHAR(150),
    "record_date" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "patient_files_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "file_audit_log" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "patient_id" VARCHAR(50) NOT NULL,
    "file_id" INTEGER,
    "action" VARCHAR(30) NOT NULL,
    "staff_id" INTEGER NOT NULL,
    "staff_name" VARCHAR(200) NOT NULL,
    "details" TEXT,
    "ip_address" VARCHAR(45),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "file_audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "staff" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "staff_code" VARCHAR(50) NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "email" VARCHAR(150),
    "phone" VARCHAR(50),
    "role" VARCHAR(100) NOT NULL,
    "department" VARCHAR(100) NOT NULL,
    "gender" VARCHAR(20) DEFAULT 'Female',
    "date_of_birth" DATE,
    "joining_date" DATE,
    "shift" VARCHAR(100) DEFAULT 'Morning (08:00 - 16:00)',
    "status" VARCHAR(30) NOT NULL DEFAULT 'Active',
    "qualification" VARCHAR(255),
    "salary" DECIMAL(12,2) DEFAULT 0.00,
    "blood_group" VARCHAR(10),
    "emergency_contact" VARCHAR(100),
    "address" TEXT,
    "is_user" BOOLEAN NOT NULL DEFAULT false,
    "username" VARCHAR(100),
    "password_hash" VARCHAR(255),
    "avatar_url" VARCHAR(500),
    "face_embedding" JSONB,
    "account_status" VARCHAR(30) NOT NULL DEFAULT 'Active',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "staff_permissions" (
    "id" SERIAL NOT NULL,
    "staff_id" INTEGER NOT NULL,
    "permission_key" VARCHAR(60) NOT NULL,
    "permission_value" BOOLEAN NOT NULL DEFAULT false,
    "granted_by" INTEGER,
    "granted_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "hospital_geofence" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL DEFAULT 'Main Clinical Building',
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "radius_meters" INTEGER NOT NULL DEFAULT 150,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "hospital_geofence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "staff_attendance" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "staff_id" INTEGER NOT NULL,
    "date" DATE NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'Present',
    "check_in_time" VARCHAR(20),
    "check_out_time" VARCHAR(20),
    "working_hours" DECIMAL(4,2),
    "selfie_verified" BOOLEAN NOT NULL DEFAULT false,
    "location_verified" BOOLEAN NOT NULL DEFAULT false,
    "check_in_lat" DECIMAL(10,7),
    "check_in_lng" DECIMAL(10,7),
    "face_confidence" DECIMAL(5,4),
    "check_in_method" VARCHAR(30) DEFAULT 'manual',
    "marked_by" VARCHAR(100) DEFAULT 'System',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_attendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consultation_charges" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "charge_type" VARCHAR(100) NOT NULL,
    "charge_name" VARCHAR(255) NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consultation_charges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "online_consultations" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "patient_id" VARCHAR(50) NOT NULL,
    "doctor_id" VARCHAR(50) NOT NULL,
    "appointment_id" INTEGER,
    "status" VARCHAR(30) NOT NULL DEFAULT 'initiated',
    "diagnosis" TEXT,
    "prescription_notes" TEXT,
    "doctor_notes" TEXT,
    "consultation_fee" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    "fee_status" VARCHAR(30) NOT NULL DEFAULT 'pending',
    "started_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMPTZ,

    CONSTRAINT "online_consultations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_config" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "model_name" VARCHAR(100) NOT NULL DEFAULT 'qwen2.5:3b',
    "provider" VARCHAR(50) NOT NULL DEFAULT 'ollama',
    "api_url" VARCHAR(255) NOT NULL DEFAULT 'http://localhost:11434',
    "max_tokens" INTEGER NOT NULL DEFAULT 2048,
    "temperature" DECIMAL(3,2) NOT NULL DEFAULT 0.20,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_config_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_conversations" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "user_id" VARCHAR(100) NOT NULL,
    "user_role" VARCHAR(100) NOT NULL DEFAULT 'Admin',
    "title" VARCHAR(255) NOT NULL DEFAULT 'Clinical Query',
    "page_context" VARCHAR(100),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_chat_messages" (
    "id" SERIAL NOT NULL,
    "conversation_id" INTEGER NOT NULL,
    "role" VARCHAR(20) NOT NULL,
    "content" TEXT NOT NULL,
    "tool_calls" JSONB,
    "tokens_used" INTEGER NOT NULL DEFAULT 0,
    "response_time_ms" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_pending_actions" (
    "id" SERIAL NOT NULL,
    "conversation_id" INTEGER NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "action_type" VARCHAR(30) NOT NULL,
    "target_table" VARCHAR(100) NOT NULL,
    "description" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'pending',
    "confirmed_at" TIMESTAMPTZ,
    "executed_at" TIMESTAMPTZ,
    "error_message" TEXT,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_pending_actions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_action_log" (
    "id" SERIAL NOT NULL,
    "hospital_id" INTEGER NOT NULL,
    "user_id" VARCHAR(100) NOT NULL,
    "user_role" VARCHAR(100) NOT NULL,
    "action_id" INTEGER,
    "action_type" VARCHAR(30) NOT NULL,
    "target_table" VARCHAR(100) NOT NULL,
    "mutation_details" JSONB NOT NULL,
    "success" BOOLEAN NOT NULL DEFAULT true,
    "error_message" TEXT,
    "ip_address" VARCHAR(45),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_action_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "hospitals_hospital_code_key" ON "hospitals"("hospital_code");

-- CreateIndex
CREATE INDEX "departments_hospital_id_idx" ON "departments"("hospital_id");

-- CreateIndex
CREATE INDEX "doctors_hospital_id_idx" ON "doctors"("hospital_id");

-- CreateIndex
CREATE INDEX "doctor_day_schedules_doctor_id_idx" ON "doctor_day_schedules"("doctor_id");

-- CreateIndex
CREATE UNIQUE INDEX "doctor_day_schedules_doctor_id_day_of_week_key" ON "doctor_day_schedules"("doctor_id", "day_of_week");

-- CreateIndex
CREATE INDEX "doctor_slots_doctor_id_idx" ON "doctor_slots"("doctor_id");

-- CreateIndex
CREATE UNIQUE INDEX "patients_qr_token_key" ON "patients"("qr_token");

-- CreateIndex
CREATE INDEX "patients_hospital_id_idx" ON "patients"("hospital_id");

-- CreateIndex
CREATE INDEX "patients_phone_idx" ON "patients"("phone");

-- CreateIndex
CREATE INDEX "patients_name_surname_idx" ON "patients"("name", "surname");

-- CreateIndex
CREATE INDEX "patients_qr_token_idx" ON "patients"("qr_token");

-- CreateIndex
CREATE INDEX "beds_hospital_id_status_idx" ON "beds"("hospital_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "beds_hospital_id_bed_number_key" ON "beds"("hospital_id", "bed_number");

-- CreateIndex
CREATE INDEX "appointments_hospital_id_date_idx" ON "appointments"("hospital_id", "date");

-- CreateIndex
CREATE INDEX "appointments_patient_id_idx" ON "appointments"("patient_id");

-- CreateIndex
CREATE INDEX "appointments_doctor_id_date_slot_idx" ON "appointments"("doctor_id", "date", "slot");

-- CreateIndex
CREATE INDEX "diagnoses_appointment_id_idx" ON "diagnoses"("appointment_id");

-- CreateIndex
CREATE INDEX "prescriptions_appointment_id_idx" ON "prescriptions"("appointment_id");

-- CreateIndex
CREATE INDEX "timeline_events_patient_id_idx" ON "timeline_events"("patient_id");

-- CreateIndex
CREATE INDEX "timeline_events_appointment_id_idx" ON "timeline_events"("appointment_id");

-- CreateIndex
CREATE INDEX "patient_files_patient_id_idx" ON "patient_files"("patient_id");

-- CreateIndex
CREATE INDEX "patient_files_appointment_id_idx" ON "patient_files"("appointment_id");

-- CreateIndex
CREATE INDEX "patient_files_hospital_id_idx" ON "patient_files"("hospital_id");

-- CreateIndex
CREATE INDEX "file_audit_log_patient_id_idx" ON "file_audit_log"("patient_id");

-- CreateIndex
CREATE INDEX "file_audit_log_hospital_id_created_at_idx" ON "file_audit_log"("hospital_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "staff_username_key" ON "staff"("username");

-- CreateIndex
CREATE INDEX "staff_hospital_id_idx" ON "staff"("hospital_id");

-- CreateIndex
CREATE INDEX "staff_username_idx" ON "staff"("username");

-- CreateIndex
CREATE UNIQUE INDEX "staff_hospital_id_staff_code_key" ON "staff"("hospital_id", "staff_code");

-- CreateIndex
CREATE INDEX "staff_permissions_staff_id_idx" ON "staff_permissions"("staff_id");

-- CreateIndex
CREATE UNIQUE INDEX "staff_permissions_staff_id_permission_key_key" ON "staff_permissions"("staff_id", "permission_key");

-- CreateIndex
CREATE INDEX "hospital_geofence_hospital_id_idx" ON "hospital_geofence"("hospital_id");

-- CreateIndex
CREATE INDEX "staff_attendance_hospital_id_date_idx" ON "staff_attendance"("hospital_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "staff_attendance_staff_id_date_key" ON "staff_attendance"("staff_id", "date");

-- CreateIndex
CREATE INDEX "consultation_charges_hospital_id_idx" ON "consultation_charges"("hospital_id");

-- CreateIndex
CREATE INDEX "online_consultations_hospital_id_idx" ON "online_consultations"("hospital_id");

-- CreateIndex
CREATE INDEX "online_consultations_patient_id_idx" ON "online_consultations"("patient_id");

-- CreateIndex
CREATE UNIQUE INDEX "ai_config_hospital_id_key" ON "ai_config"("hospital_id");

-- CreateIndex
CREATE INDEX "ai_conversations_hospital_id_user_id_idx" ON "ai_conversations"("hospital_id", "user_id");

-- CreateIndex
CREATE INDEX "ai_chat_messages_conversation_id_idx" ON "ai_chat_messages"("conversation_id");

-- CreateIndex
CREATE INDEX "ai_pending_actions_status_expires_at_idx" ON "ai_pending_actions"("status", "expires_at");

-- CreateIndex
CREATE INDEX "ai_action_log_hospital_id_created_at_idx" ON "ai_action_log"("hospital_id", "created_at");

-- AddForeignKey
ALTER TABLE "departments" ADD CONSTRAINT "departments_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctors" ADD CONSTRAINT "doctors_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctors" ADD CONSTRAINT "doctors_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_categories" ADD CONSTRAINT "doctor_categories_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_categories" ADD CONSTRAINT "doctor_categories_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_day_schedules" ADD CONSTRAINT "doctor_day_schedules_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_slots" ADD CONSTRAINT "doctor_slots_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "beds" ADD CONSTRAINT "beds_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "beds" ADD CONSTRAINT "beds_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "diagnoses" ADD CONSTRAINT "diagnoses_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "timeline_events" ADD CONSTRAINT "timeline_events_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "timeline_events" ADD CONSTRAINT "timeline_events_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_files" ADD CONSTRAINT "patient_files_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_files" ADD CONSTRAINT "patient_files_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_files" ADD CONSTRAINT "patient_files_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "file_audit_log" ADD CONSTRAINT "file_audit_log_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "staff" ADD CONSTRAINT "staff_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "staff_permissions" ADD CONSTRAINT "staff_permissions_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "staff"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hospital_geofence" ADD CONSTRAINT "hospital_geofence_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "staff_attendance" ADD CONSTRAINT "staff_attendance_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "staff_attendance" ADD CONSTRAINT "staff_attendance_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "staff"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consultation_charges" ADD CONSTRAINT "consultation_charges_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "online_consultations" ADD CONSTRAINT "online_consultations_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "online_consultations" ADD CONSTRAINT "online_consultations_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "online_consultations" ADD CONSTRAINT "online_consultations_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "online_consultations" ADD CONSTRAINT "online_consultations_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_config" ADD CONSTRAINT "ai_config_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_conversations" ADD CONSTRAINT "ai_conversations_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_chat_messages" ADD CONSTRAINT "ai_chat_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "ai_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_pending_actions" ADD CONSTRAINT "ai_pending_actions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "ai_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_pending_actions" ADD CONSTRAINT "ai_pending_actions_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_action_log" ADD CONSTRAINT "ai_action_log_hospital_id_fkey" FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_action_log" ADD CONSTRAINT "ai_action_log_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "ai_pending_actions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
