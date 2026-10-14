import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DIRECT_URL || process.env.DATABASE_URL,
    },
  },
});

const tables = [
  'hospitals',
  'departments',
  'doctors',
  'doctor_categories',
  'doctor_day_schedules',
  'doctor_slots',
  'patients',
  'beds',
  'appointments',
  'diagnoses',
  'prescriptions',
  'timeline_events',
  'patient_files',
  'file_audit_log',
  'staff',
  'staff_permissions',
  'consultation_charges',
  'hospital_geofence',
  'staff_attendance',
  'online_consultations',
  'ai_config',
  'ai_conversations',
  'ai_chat_messages',
  'ai_pending_actions',
  'ai_action_log',
];

async function main() {
  console.log('--- Enabling Row Level Security (RLS) on all public tables ---');
  for (const table of tables) {
    try {
      await prisma.$executeRawUnsafe(`ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY;`);
      console.log(`[RLS] Enabled on table: public.${table}`);
    } catch (e: any) {
      console.error(`[RLS] Error on ${table}: ${e.message}`);
    }
  }
  console.log('--- All tables now have Row Level Security enabled! ---');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
