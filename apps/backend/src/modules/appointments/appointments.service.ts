import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStageDto } from './dto/update-stage.dto';

@Injectable()
export class AppointmentsService {
  private readonly logger = new Logger(AppointmentsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. Query appointments by filters (date, doctorId, status)
   */
  async findMany(
    hospitalId: number,
    filters: { date?: string; doctorId?: string; status?: string; patientId?: string },
  ) {
    const where: any = { hospitalId };

    if (filters.date) {
      const d = new Date(filters.date);
      d.setHours(0, 0, 0, 0);
      where.date = d;
    }

    if (filters.doctorId) {
      where.doctorId = filters.doctorId;
    }

    if (filters.patientId) {
      where.patientId = filters.patientId;
    }

    if (filters.status) {
      where.status = filters.status;
    }

    return this.prisma.appointment.findMany({
      where,
      orderBy: [{ date: 'asc' }, { tokenNumber: 'asc' }],
      include: {
        patient: {
          select: {
            id: true,
            name: true,
            surname: true,
            phone: true,
            age: true,
            gender: true,
            bloodGroup: true,
            qrToken: true,
          },
        },
        doctor: {
          select: {
            id: true,
            name: true,
            departmentId: true,
            consultationFee: true,
          },
        },
        diagnoses: true,
        prescriptions: true,
      },
    });
  }

  /**
   * 2. Find Appointment by ID
   */
  async findById(hospitalId: number, id: number) {
    const appt = await this.prisma.appointment.findFirst({
      where: { id, hospitalId },
      include: {
        patient: true,
        doctor: {
          include: { department: true },
        },
        diagnoses: true,
        prescriptions: true,
        timelineEvents: true,
      },
    });

    if (!appt) {
      throw new NotFoundException(`Appointment #${id} not found.`);
    }

    return appt;
  }

  /**
   * 3. Book Appointment with Anti-Collision Locking & Sequential Token Assignment
   */
  async create(hospitalId: number, dto: CreateAppointmentDto, bookedByStaffId?: number) {
    // 1. Verify Patient & Doctor exist
    const [patient, doctor] = await Promise.all([
      this.prisma.patient.findFirst({ where: { id: dto.patientId, hospitalId } }),
      this.prisma.doctor.findFirst({ where: { id: dto.doctorId, hospitalId } }),
    ]);

    if (!patient) {
      throw new NotFoundException(`Patient MRN "${dto.patientId}" does not exist.`);
    }
    if (!doctor) {
      throw new NotFoundException(`Doctor "${dto.doctorId}" does not exist.`);
    }

    const apptDate = new Date(dto.date);
    apptDate.setHours(0, 0, 0, 0);

    // 2. Transactional Slot Anti-Collision Guard & Sequential Token Assignment
    return this.prisma.$transaction(async (tx) => {
      // Check collision
      const existingSlot = await tx.appointment.findFirst({
        where: {
          hospitalId,
          doctorId: dto.doctorId,
          date: apptDate,
          slot: dto.slot,
          status: { notIn: ['Cancelled', 'No-Show'] },
        },
      });

      if (existingSlot) {
        throw new ConflictException(
          `Doctor ${doctor.name} already has an appointment booked for ${dto.slot} on ${dto.date}. Please select an available slot.`,
        );
      }

      // Compute sequential token number for this doctor on this day
      const countForDay = await tx.appointment.count({
        where: {
          hospitalId,
          doctorId: dto.doctorId,
          date: apptDate,
        },
      });

      const nextTokenNumber = countForDay + 1;

      // Create appointment
      const newAppointment = await tx.appointment.create({
        data: {
          hospitalId,
          patientId: dto.patientId,
          doctorId: dto.doctorId,
          type: dto.type || 'General Consultation',
          date: apptDate,
          slot: dto.slot,
          tokenNumber: nextTokenNumber,
          tokenAssignedAt: new Date(),
          tokenAssignedBy: bookedByStaffId,
          symptoms: dto.symptoms,
          allergies: dto.allergies,
          status: 'Scheduled',
          stage: 1, // Stage 1: Waiting / Arrived
          bookingType: dto.bookingType || 'walk-in',
        },
        include: {
          patient: true,
          doctor: true,
        },
      });

      // Add to patient timeline
      await tx.timelineEvent.create({
        data: {
          patientId: patient.id,
          appointmentId: newAppointment.id,
          eventTime: dto.slot,
          eventDescription: `Appointment booked with ${doctor.name} (${dto.slot}). Token #${nextTokenNumber} allocated.`,
        },
      });

      this.logger.log(
        `Appointment booked: Patient ${patient.name} with Doctor ${doctor.name} (Token #${nextTokenNumber}, Slot ${dto.slot})`,
      );

      return newAppointment;
    });
  }

  /**
   * 4. Retrieve Live Triage Queue Grouped by Stages
   */
  async getQueue(hospitalId: number, dateStr?: string) {
    const today = dateStr ? new Date(dateStr) : new Date();
    today.setHours(0, 0, 0, 0);

    const appointments = await this.prisma.appointment.findMany({
      where: {
        hospitalId,
        date: today,
        status: { notIn: ['Cancelled'] },
      },
      orderBy: [{ tokenNumber: 'asc' }],
      include: {
        patient: {
          select: {
            id: true,
            name: true,
            surname: true,
            phone: true,
            age: true,
            gender: true,
            bloodGroup: true,
          },
        },
        doctor: {
          select: {
            id: true,
            name: true,
            departmentId: true,
          },
        },
        diagnoses: true,
        prescriptions: true,
      },
    });

    const waiting = appointments.filter((a) => a.stage === 1 || a.status === 'Scheduled');
    const inConsultation = appointments.filter((a) => a.stage === 2 || a.status === 'In-Consultation');
    const observation = appointments.filter((a) => a.stage === 3);
    const completed = appointments.filter((a) => a.stage >= 4 || a.status === 'Completed');

    return {
      date: today.toISOString().split('T')[0],
      totalAppointments: appointments.length,
      counts: {
        waiting: waiting.length,
        inConsultation: inConsultation.length,
        observation: observation.length,
        completed: completed.length,
      },
      queue: {
        waiting,
        inConsultation,
        observation,
        completed,
      },
    };
  }

  /**
   * 5. Update Appointment Queue Stage
   */
  async updateStage(hospitalId: number, id: number, dto: UpdateStageDto) {
    const appt = await this.findById(hospitalId, id);

    let derivedStatus = dto.status;
    if (!derivedStatus) {
      switch (dto.stage) {
        case 1:
          derivedStatus = 'Scheduled';
          break;
        case 2:
          derivedStatus = 'In-Consultation';
          break;
        case 3:
          derivedStatus = 'Observation';
          break;
        case 4:
          derivedStatus = 'Completed';
          break;
        case 5:
          derivedStatus = 'Discharged';
          break;
      }
    }

    const updated = await this.prisma.appointment.update({
      where: { id },
      data: {
        stage: dto.stage,
        status: derivedStatus,
        doctorNotes: dto.doctorNotes !== undefined ? dto.doctorNotes : appt.doctorNotes,
      },
      include: {
        patient: true,
        doctor: true,
      },
    });

    // Record stage progression in timeline
    await this.prisma.timelineEvent.create({
      data: {
        patientId: appt.patientId,
        appointmentId: appt.id,
        eventTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        eventDescription: `Queue stage updated to Stage ${dto.stage} (${derivedStatus}).`,
      },
    });

    return updated;
  }
}
