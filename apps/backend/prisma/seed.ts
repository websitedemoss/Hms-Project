import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DIRECT_URL || process.env.DATABASE_URL,
    },
  },
});

async function main() {
  console.log('--- Starting Database Seeding ---');

  // 1. Hospital Anchor
  const hospital = await prisma.hospital.upsert({
    where: { hospitalCode: 'MEDICARE-01' },
    update: {},
    create: {
      hospitalCode: 'MEDICARE-01',
      name: 'Medicare Hospital & I.C.U',
      tagline: 'Committed to Clinical Excellence & Compassionate Care',
      phone: '+91 98765 43210',
      email: 'contact@medicarehospital.in',
      address: '123 Healthcare Boulevard, Medical Zone, Ahmedabad, Gujarat',
    },
  });
  console.log(`[Seed] Hospital created: ${hospital.name} (ID: ${hospital.id})`);

  // 2. Clinical Departments
  const departmentsData = [
    { id: 'cardiology', name: 'Cardiology', icon: 'fa-heartbeat' },
    { id: 'neurology', name: 'Neurology', icon: 'fa-brain' },
    { id: 'orthopedics', name: 'Orthopedics', icon: 'fa-bone' },
    { id: 'general_medicine', name: 'General Medicine', icon: 'fa-user-md' },
    { id: 'pediatrics', name: 'Pediatrics', icon: 'fa-baby' },
  ];

  for (const dept of departmentsData) {
    await prisma.department.upsert({
      where: { id: dept.id },
      update: {},
      create: {
        id: dept.id,
        hospitalId: hospital.id,
        name: dept.name,
        icon: dept.icon,
      },
    });
  }
  console.log(`[Seed] ${departmentsData.length} Departments seeded.`);

  // 3. Doctors
  const doctorsData = [
    {
      id: 'DOC001',
      name: 'Dr. Rajesh Sharma',
      departmentId: 'cardiology',
      degree: 'MBBS, MD, DM (Cardiology)',
      experience: '15 Years',
      phone: '+91 98765 00001',
      consultationFee: 800.0,
      status: 'Available',
    },
    {
      id: 'DOC002',
      name: 'Dr. Priya Desai',
      departmentId: 'neurology',
      degree: 'MBBS, MS, MCh (Neuro Surgery)',
      experience: '12 Years',
      phone: '+91 98765 00002',
      consultationFee: 1000.0,
      status: 'Available',
    },
    {
      id: 'DOC003',
      name: 'Dr. Amit Verma',
      departmentId: 'orthopedics',
      degree: 'MBBS, MS (Orthopedics)',
      experience: '10 Years',
      phone: '+91 98765 00003',
      consultationFee: 700.0,
      status: 'Available',
    },
    {
      id: 'DOC004',
      name: 'Dr. Ananya Iyer',
      departmentId: 'general_medicine',
      degree: 'MBBS, MD (General Medicine)',
      experience: '8 Years',
      phone: '+91 98765 00004',
      consultationFee: 500.0,
      status: 'Available',
    },
  ];

  const standardTimeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
  ];

  const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  for (const doc of doctorsData) {
    await prisma.doctor.upsert({
      where: { id: doc.id },
      update: {},
      create: {
        id: doc.id,
        hospitalId: hospital.id,
        name: doc.name,
        departmentId: doc.departmentId,
        degree: doc.degree,
        experience: doc.experience,
        phone: doc.phone,
        consultationFee: doc.consultationFee,
        status: doc.status,
      },
    });

    // Link Specialty Category
    await prisma.doctorCategory.upsert({
      where: {
        doctorId_departmentId: {
          doctorId: doc.id,
          departmentId: doc.departmentId,
        },
      },
      update: {},
      create: {
        doctorId: doc.id,
        departmentId: doc.departmentId,
      },
    });

    // Seed Schedules
    for (const day of daysOfWeek) {
      await prisma.doctorDaySchedule.upsert({
        where: {
          uq_doctor_day: {
            doctorId: doc.id,
            dayOfWeek: day,
          },
        },
        update: {},
        create: {
          doctorId: doc.id,
          dayOfWeek: day,
          isAvailable: true,
          startTime: '09:00 AM',
          endTime: '07:00 PM',
          durationMinutes: 30,
          breakStart: '01:00 PM',
          breakEnd: '04:30 PM',
        },
      });
    }

    // Seed Standard Time Slots
    for (const slot of standardTimeSlots) {
      const existingSlot = await prisma.doctorSlot.findFirst({
        where: { doctorId: doc.id, timeSlot: slot },
      });
      if (!existingSlot) {
        await prisma.doctorSlot.create({
          data: {
            doctorId: doc.id,
            timeSlot: slot,
          },
        });
      }
    }
  }
  console.log(`[Seed] ${doctorsData.length} Doctors with schedules and slots seeded.`);

  // 4. Inpatient Beds & Wards
  const bedsData = [
    { id: 'BED-ICU-01', bedNumber: 'ICU-01', type: 'ICU', wing: 'Critical Care Unit' },
    { id: 'BED-ICU-02', bedNumber: 'ICU-02', type: 'ICU', wing: 'Critical Care Unit' },
    { id: 'BED-ICU-03', bedNumber: 'ICU-03', type: 'ICU', wing: 'Critical Care Unit' },
    { id: 'BED-ICU-04', bedNumber: 'ICU-04', type: 'ICU', wing: 'Critical Care Unit' },
    { id: 'BED-GEN-01', bedNumber: 'GEN-01', type: 'General Ward', wing: 'Ward A' },
    { id: 'BED-GEN-02', bedNumber: 'GEN-02', type: 'General Ward', wing: 'Ward A' },
    { id: 'BED-GEN-03', bedNumber: 'GEN-03', type: 'General Ward', wing: 'Ward B' },
    { id: 'BED-GEN-04', bedNumber: 'GEN-04', type: 'General Ward', wing: 'Ward B' },
    { id: 'BED-PVT-01', bedNumber: 'PVT-01', type: 'Private Room', wing: 'Executive Wing' },
    { id: 'BED-PVT-02', bedNumber: 'PVT-02', type: 'Private Room', wing: 'Executive Wing' },
  ];

  for (const bed of bedsData) {
    await prisma.bed.upsert({
      where: { id: bed.id },
      update: {},
      create: {
        id: bed.id,
        hospitalId: hospital.id,
        bedNumber: bed.bedNumber,
        type: bed.type,
        wing: bed.wing,
        status: 'Available',
      },
    });
  }
  console.log(`[Seed] ${bedsData.length} Inpatient Beds seeded.`);

  // 5. Master Consultation Charges
  const chargesData = [
    { chargeType: 'OPD', chargeName: 'General OPD Consultation', amount: 500.0 },
    { chargeType: 'OPD', chargeName: 'Specialist Consultation', amount: 800.0 },
    { chargeType: 'OPD', chargeName: 'Super-Specialist Consultation', amount: 1200.0 },
    { chargeType: 'Emergency', chargeName: 'Emergency & Casualty Triage', amount: 1500.0 },
    { chargeType: 'Follow-up', chargeName: 'Follow-up Consultation (Within 7 Days)', amount: 250.0 },
  ];

  for (const charge of chargesData) {
    const existing = await prisma.consultationCharge.findFirst({
      where: { hospitalId: hospital.id, chargeName: charge.chargeName },
    });
    if (!existing) {
      await prisma.consultationCharge.create({
        data: {
          hospitalId: hospital.id,
          chargeType: charge.chargeType,
          chargeName: charge.chargeName,
          amount: charge.amount,
          isActive: true,
        },
      });
    }
  }
  console.log(`[Seed] ${chargesData.length} Consultation Charges seeded.`);

  // 6. Hospital Geofence Boundary
  const existingGeofence = await prisma.hospitalGeofence.findFirst({
    where: { hospitalId: hospital.id },
  });
  if (!existingGeofence) {
    await prisma.hospitalGeofence.create({
      data: {
        hospitalId: hospital.id,
        name: 'Medicare Main Campus',
        latitude: 23.0225,
        longitude: 72.5714,
        radiusMeters: 250,
      },
    });
    console.log('[Seed] Hospital Geofence seeded (250m radius).');
  }

  // 7. AI Config
  await prisma.aiConfig.upsert({
    where: { hospitalId: hospital.id },
    update: {},
    create: {
      hospitalId: hospital.id,
      enabled: true,
      modelName: 'qwen2.5:3b',
      provider: 'ollama',
      apiUrl: 'http://localhost:11434',
      maxTokens: 2048,
      temperature: 0.2,
    },
  });
  console.log('[Seed] BHOOMA AI config initialized.');

  // 8. Staff Accounts & Permissions
  const adminPasswordHash = await argon2.hash('Admin@1234');
  const staffPasswordHash = await argon2.hash('Staff@1234');
  const doctorPasswordHash = await argon2.hash('Doctor@1234');

  const staffMembers = [
    {
      staffCode: 'STF-ADM-001',
      firstName: 'Hospital',
      lastName: 'Administrator',
      email: 'admin@medicare.in',
      phone: '+91 98765 11111',
      role: 'Super Admin',
      department: 'Administration',
      username: 'admin',
      passwordHash: adminPasswordHash,
      permissions: [
        'dashboard',
        'patients',
        'appointments',
        'queue',
        'doctors',
        'staff',
        'attendance',
        'bed',
        'medical_files',
        'bhooma_ai',
        'settings',
      ],
    },
    {
      staffCode: 'STF-DOC-001',
      firstName: 'Rajesh',
      lastName: 'Sharma',
      email: 'dr.rajesh@medicare.in',
      phone: '+91 98765 00001',
      role: 'Doctor',
      department: 'Cardiology',
      username: 'dr.rajesh',
      passwordHash: doctorPasswordHash,
      permissions: [
        'dashboard',
        'patients',
        'appointments',
        'queue',
        'bed',
        'medical_files',
        'bhooma_ai',
      ],
    },
    {
      staffCode: 'STF-REC-001',
      firstName: 'Pooja',
      lastName: 'Shah',
      email: 'reception@medicare.in',
      phone: '+91 98765 22222',
      role: 'Receptionist',
      department: 'Front Desk',
      username: 'reception',
      passwordHash: staffPasswordHash,
      permissions: ['dashboard', 'patients', 'appointments', 'queue', 'attendance'],
    },
    {
      staffCode: 'STF-NUR-001',
      firstName: 'Sunita',
      lastName: 'Kaur',
      email: 'nurse@medicare.in',
      phone: '+91 98765 33333',
      role: 'Nurse',
      department: 'ICU Ward',
      username: 'nurse.sunita',
      passwordHash: staffPasswordHash,
      permissions: ['dashboard', 'patients', 'appointments', 'bed', 'medical_files', 'attendance'],
    },
  ];

  const allAvailablePermissions = [
    'dashboard',
    'patients',
    'appointments',
    'queue',
    'doctors',
    'staff',
    'attendance',
    'bed',
    'medical_files',
    'bhooma_ai',
    'settings',
  ];

  for (const stf of staffMembers) {
    const staffUser = await prisma.staff.upsert({
      where: { username: stf.username },
      update: {},
      create: {
        hospitalId: hospital.id,
        staffCode: stf.staffCode,
        firstName: stf.firstName,
        lastName: stf.lastName,
        email: stf.email,
        phone: stf.phone,
        role: stf.role,
        department: stf.department,
        isUser: true,
        username: stf.username,
        passwordHash: stf.passwordHash,
        accountStatus: 'Active',
      },
    });

    // Populate all 11 permissions with true/false based on role grant
    for (const permKey of allAvailablePermissions) {
      const isGranted = stf.permissions.includes(permKey);
      await prisma.staffPermission.upsert({
        where: {
          uq_staff_perm: {
            staffId: staffUser.id,
            permissionKey: permKey,
          },
        },
        update: { permissionValue: isGranted },
        create: {
          staffId: staffUser.id,
          permissionKey: permKey,
          permissionValue: isGranted,
        },
      });
    }
  }
  console.log(`[Seed] ${staffMembers.length} Staff accounts & granular permissions seeded.`);

  // 9. Sample Patients & Clinical Journey
  const patient1 = await prisma.patient.upsert({
    where: { id: 'CP-2026-001' },
    update: {},
    create: {
      id: 'CP-2026-001',
      hospitalId: hospital.id,
      name: 'Ramesh',
      surname: 'Patel',
      fatherName: 'Harishbhai Patel',
      phone: '+91 98250 12345',
      age: 54,
      gender: 'Male',
      bloodGroup: 'B+',
      emergencyContactName: 'Geeta Patel (Wife)',
      emergencyContactPhone: '+91 98250 12346',
    },
  });

  const patient2 = await prisma.patient.upsert({
    where: { id: 'CP-2026-002' },
    update: {},
    create: {
      id: 'CP-2026-002',
      hospitalId: hospital.id,
      name: 'Meena',
      surname: 'Shah',
      fatherName: 'Pravinbhai Shah',
      phone: '+91 98251 67890',
      age: 36,
      gender: 'Female',
      bloodGroup: 'O+',
      emergencyContactName: 'Ketan Shah (Husband)',
      emergencyContactPhone: '+91 98251 67891',
    },
  });
  console.log('[Seed] Sample Patients created: CP-2026-001 (Ramesh), CP-2026-002 (Meena).');

  // Sample Appointment for Ramesh Patel
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const appointment1 = await prisma.appointment.create({
    data: {
      hospitalId: hospital.id,
      patientId: patient1.id,
      doctorId: 'DOC001',
      type: 'General Consultation',
      date: today,
      slot: '10:00 AM',
      tokenNumber: 1,
      tokenAssignedAt: new Date(),
      symptoms: 'Mild chest tightness on exertion, shortness of breath for 3 days',
      allergies: 'Penicillin, Sulfa drugs',
      status: 'Completed',
      stage: 3,
      doctorNotes: 'BP 138/88 mmHg. ECG shows normal sinus rhythm. Advised 2D Echocardiogram.',
      bookingType: 'walk-in',
    },
  });

  // Clinical Diagnosis
  await prisma.diagnosis.create({
    data: {
      appointmentId: appointment1.id,
      icd10Code: 'I10',
      description: 'Essential Primary Hypertension & Exertional Dyspnea',
    },
  });

  // Clinical Prescription
  await prisma.prescription.createMany({
    data: [
      {
        appointmentId: appointment1.id,
        medicineName: 'Tab. Telmisartan 40mg',
        dosage: '1 Tab',
        frequency: 'OD (Morning after breakfast)',
        duration: '30 Days',
        instructions: 'Monitor BP weekly. Low salt diet.',
      },
      {
        appointmentId: appointment1.id,
        medicineName: 'Tab. Atorvastatin 10mg',
        dosage: '1 Tab',
        frequency: 'HS (At bedtime)',
        duration: '30 Days',
        instructions: 'Take after dinner.',
      },
    ],
  });

  // Timeline Event
  await prisma.timelineEvent.create({
    data: {
      patientId: patient1.id,
      appointmentId: appointment1.id,
      eventTime: '10:30 AM',
      eventDescription: 'Consultation completed by Dr. Rajesh Sharma. Prescriptions issued.',
    },
  });

  console.log('[Seed] Sample Appointment, Diagnosis, and Prescriptions seeded.');
  console.log('--- Database Seeding Completed Successfully! ---');
}

main()
  .catch((e) => {
    console.error('Seeding failed with error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
