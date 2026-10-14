import {
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SaveConsultationDto } from './dto/save-consultation.dto';

export const LATIN_FREQUENCY_TRANSLATIONS: Record<string, string> = {
  OD: 'Once Daily (Morning)',
  BD: 'Twice Daily (Morning, Night)',
  BID: 'Twice Daily (Morning, Night)',
  TDS: '3 Times Daily (Morning, Afternoon, Night)',
  TID: '3 Times Daily (Morning, Afternoon, Night)',
  QID: '4 Times Daily (Every 6 Hours)',
  HS: 'At Bedtime (After Dinner)',
  QHS: 'At Bedtime (After Dinner)',
  SOS: 'As Needed / Emergency',
  PRN: 'As Needed',
  STAT: 'Immediately (Single Dose)',
};

export function translateFrequency(code: string): string {
  const upper = code.trim().toUpperCase();
  return LATIN_FREQUENCY_TRANSLATIONS[upper] || code;
}

@Injectable()
export class ConsultationsService {
  private readonly logger = new Logger(ConsultationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. Get Consultation Details for an Appointment
   */
  async getConsultation(hospitalId: number, appointmentId: number) {
    const appt = await this.prisma.appointment.findFirst({
      where: { id: appointmentId, hospitalId },
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
      throw new NotFoundException(`Appointment #${appointmentId} not found.`);
    }

    return appt;
  }

  /**
   * 2. Save Complete 4-Step Consultation Transaction
   */
  async saveConsultation(
    hospitalId: number,
    appointmentId: number,
    dto: SaveConsultationDto,
    doctorId?: string,
  ) {
    const appt = await this.prisma.appointment.findFirst({
      where: { id: appointmentId, hospitalId },
      include: {
        patient: true,
        doctor: true,
      },
    });

    if (!appt) {
      throw new NotFoundException(`Appointment #${appointmentId} not found.`);
    }

    const isAdmitted =
      dto.disposition.toLowerCase().includes('admit') && dto.bedNumber;
    const finalStatus = isAdmitted ? 'Admitted' : 'Completed';
    const finalStage = isAdmitted ? 3 : 4; // 3: Inpatient/Observation, 4: Completed

    return this.prisma.$transaction(async (tx) => {
      // 1. Delete previous diagnoses and prescriptions if re-saving
      await tx.diagnosis.deleteMany({ where: { appointmentId } });
      await tx.prescription.deleteMany({ where: { appointmentId } });

      // 2. Insert Diagnoses
      if (dto.diagnoses && dto.diagnoses.length > 0) {
        await tx.diagnosis.createMany({
          data: dto.diagnoses.map((d) => ({
            appointmentId,
            icd10Code: d.icd10Code || null,
            description: d.description.trim(),
          })),
        });
      }

      // 3. Insert Prescriptions with Latin translation support
      if (dto.prescriptions && dto.prescriptions.length > 0) {
        await tx.prescription.createMany({
          data: dto.prescriptions.map((p) => {
            const translatedFreq = translateFrequency(p.frequency);
            const fullFreq =
              translatedFreq !== p.frequency
                ? `${p.frequency.toUpperCase()} — ${translatedFreq}`
                : p.frequency;

            return {
              appointmentId,
              medicineName: p.medicineName.trim(),
              dosage: p.dosage.trim(),
              frequency: fullFreq,
              duration: p.duration.trim(),
              instructions: p.instructions?.trim() || null,
            };
          }),
        });
      }

      // 4. Update Bed if Admitted
      if (isAdmitted && dto.bedNumber) {
        // Look up bed
        const bed = await tx.bed.findFirst({
          where: { hospitalId, bedNumber: dto.bedNumber },
        });

        if (bed) {
          await tx.bed.update({
            where: { id: bed.id },
            data: {
              status: 'Occupied',
              patientId: appt.patientId,
            },
          });
        }
      }

      // 5. Update Appointment
      const updatedAppt = await tx.appointment.update({
        where: { id: appointmentId },
        data: {
          status: finalStatus,
          stage: finalStage,
          bedNumber: dto.bedNumber || null,
          doctorNotes: dto.doctorNotes || null,
        },
        include: {
          patient: true,
          doctor: true,
          diagnoses: true,
          prescriptions: true,
        },
      });

      // 6. Record in Patient Timeline
      const diagSummary = dto.diagnoses.map((d) => d.description).join(', ');
      await tx.timelineEvent.create({
        data: {
          patientId: appt.patientId,
          appointmentId: appt.id,
          eventTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          eventDescription: `Consultation completed by Dr. ${appt.doctor.name}. Diagnoses: [${diagSummary}]. Disposition: ${dto.disposition}.`,
        },
      });

      this.logger.log(
        `Consultation saved for Appointment #${appointmentId} (Patient: ${appt.patient.name}, Status: ${finalStatus})`,
      );

      return updatedAppt;
    });
  }
}
