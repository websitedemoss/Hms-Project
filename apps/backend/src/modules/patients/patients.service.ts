import {
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { CheckDuplicatePatientDto } from './dto/check-duplicate.dto';
import { PatientQueryDto } from './dto/patient-query.dto';

@Injectable()
export class PatientsService {
  private readonly logger = new Logger(PatientsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. Query & Search Patients (Paginated & Scoped by Hospital Tenant)
   */
  async findMany(hospitalId: number, query: PatientQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 15));
    const skip = (page - 1) * limit;

    const where: any = { hospitalId };

    if (query.q && query.q.trim().length > 0) {
      const searchTerm = query.q.trim();
      where.OR = [
        { id: { contains: searchTerm, mode: 'insensitive' } },
        { name: { contains: searchTerm, mode: 'insensitive' } },
        { surname: { contains: searchTerm, mode: 'insensitive' } },
        { phone: { contains: searchTerm } },
      ];
    }

    const [total, patients] = await Promise.all([
      this.prisma.patient.count({ where }),
      this.prisma.patient.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: {
            select: {
              appointments: true,
              patientFiles: true,
            },
          },
        },
      }),
    ]);

    return {
      data: patients,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * 2. Find Single Patient by MRN
   */
  async findById(hospitalId: number, id: string) {
    const patient = await this.prisma.patient.findFirst({
      where: { id, hospitalId },
      include: {
        hospital: {
          select: { id: true, name: true, hospitalCode: true },
        },
      },
    });

    if (!patient) {
      throw new NotFoundException(`Patient with MRN "${id}" not found.`);
    }

    return patient;
  }

  /**
   * 3. Complete Patient Clinical Dossier (Demographics, Appointments, Diagnoses, Rx, Timeline)
   */
  async getDossier(hospitalId: number, id: string) {
    const patient = await this.prisma.patient.findFirst({
      where: { id, hospitalId },
      include: {
        hospital: {
          select: { id: true, name: true, hospitalCode: true },
        },
        appointments: {
          orderBy: { date: 'desc' },
          include: {
            doctor: {
              select: { id: true, name: true, departmentId: true },
            },
            diagnoses: true,
            prescriptions: true,
            timelineEvents: true,
          },
        },
        timelineEvents: {
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
        patientFiles: {
          orderBy: { recordDate: 'desc' },
          select: {
            id: true,
            title: true,
            category: true,
            storagePath: true,
            mimeType: true,
            fileSizeBytes: true,
            recordDate: true,
          },
        },
      },
    });

    if (!patient) {
      throw new NotFoundException(`Patient clinical dossier for "${id}" not found.`);
    }

    return patient;
  }

  /**
   * 4. Check Duplicate Patient Profile
   */
  async checkDuplicate(hospitalId: number, dto: CheckDuplicatePatientDto) {
    const nameMatch = dto.name.trim();
    const surnameMatch = dto.surname.trim();

    const conditions: any[] = [
      {
        AND: [
          { name: { equals: nameMatch, mode: 'insensitive' } },
          { surname: { equals: surnameMatch, mode: 'insensitive' } },
        ],
      },
    ];

    if (dto.phone && dto.phone.trim().length >= 7) {
      conditions.push({ phone: { equals: dto.phone.trim() } });
    }

    const matches = await this.prisma.patient.findMany({
      where: {
        hospitalId,
        OR: conditions,
      },
      select: {
        id: true,
        name: true,
        surname: true,
        phone: true,
        age: true,
        gender: true,
        createdAt: true,
      },
      take: 5,
    });

    return {
      isDuplicate: matches.length > 0,
      matches,
    };
  }

  /**
   * 5. Register New Patient (Generates Atomic MRN: CP-YYYY-XXX & QR Token)
   */
  async create(hospitalId: number, dto: CreatePatientDto) {
    const currentYear = new Date().getFullYear();
    const prefix = `CP-${currentYear}`;

    // Compute next atomic MRN for this year
    const latestPatient = await this.prisma.patient.findFirst({
      where: {
        hospitalId,
        id: { startsWith: prefix },
      },
      orderBy: { id: 'desc' },
      select: { id: true },
    });

    let nextNumber = 1;
    if (latestPatient && latestPatient.id) {
      const parts = latestPatient.id.split('-');
      if (parts.length === 3) {
        const parsed = parseInt(parts[2], 10);
        if (!isNaN(parsed)) {
          nextNumber = parsed + 1;
        }
      }
    }

    const formattedId = `${prefix}-${String(nextNumber).padStart(3, '0')}`;
    const qrToken = randomUUID();

    const patient = await this.prisma.patient.create({
      data: {
        id: formattedId,
        hospitalId,
        name: dto.name.trim(),
        surname: dto.surname.trim(),
        fatherName: dto.fatherName?.trim(),
        phone: dto.phone?.trim(),
        age: dto.age,
        gender: dto.gender,
        bloodGroup: dto.bloodGroup,
        emergencyContactName: dto.emergencyContactName?.trim(),
        emergencyContactPhone: dto.emergencyContactPhone?.trim(),
        qrToken,
      },
    });

    // Create initial timeline event
    await this.prisma.timelineEvent.create({
      data: {
        patientId: patient.id,
        eventTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        eventDescription: `Patient registered with MRN ${patient.id}. Lifetime QR token generated.`,
      },
    });

    this.logger.log(`New patient registered: ${patient.name} ${patient.surname} [MRN: ${patient.id}]`);
    return patient;
  }

  /**
   * 6. Update Patient Demographics
   */
  async update(hospitalId: number, id: string, dto: Partial<CreatePatientDto>) {
    await this.findById(hospitalId, id);

    return this.prisma.patient.update({
      where: { id },
      data: {
        name: dto.name?.trim(),
        surname: dto.surname?.trim(),
        fatherName: dto.fatherName?.trim(),
        phone: dto.phone?.trim(),
        age: dto.age,
        gender: dto.gender,
        bloodGroup: dto.bloodGroup,
        emergencyContactName: dto.emergencyContactName?.trim(),
        emergencyContactPhone: dto.emergencyContactPhone?.trim(),
      },
    });
  }
}
