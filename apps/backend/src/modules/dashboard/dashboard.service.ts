import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Aggregate Real-Time Hospital KPIs and Live Clinical Statistics
   */
  async getOverview(hospitalId: number) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalPatients,
      todayAppointments,
      waitingQueue,
      inConsultation,
      occupiedBeds,
      totalBeds,
      activeDoctors,
      emergencyCases,
      recentActivity,
    ] = await Promise.all([
      this.prisma.patient.count({ where: { hospitalId } }),
      this.prisma.appointment.count({ where: { hospitalId, date: today } }),
      this.prisma.appointment.count({ where: { hospitalId, date: today, stage: 1 } }),
      this.prisma.appointment.count({ where: { hospitalId, date: today, stage: 2 } }),
      this.prisma.bed.count({ where: { hospitalId, status: 'Occupied' } }),
      this.prisma.bed.count({ where: { hospitalId } }),
      this.prisma.doctor.count({ where: { hospitalId, status: 'Available' } }),
      this.prisma.appointment.count({
        where: {
          hospitalId,
          date: today,
          OR: [{ type: { contains: 'Emergency', mode: 'insensitive' } }, { bedNumber: { contains: 'ICU' } }],
        },
      }),
      this.prisma.timelineEvent.findMany({
        where: { patient: { hospitalId } },
        orderBy: { createdAt: 'desc' },
        take: 6,
        include: {
          patient: {
            select: { id: true, name: true, surname: true },
          },
        },
      }),
    ]);

    return {
      kpis: {
        totalPatients,
        todayAppointments,
        waitingQueue,
        inConsultation,
        bedOccupancy: {
          occupied: occupiedBeds,
          total: totalBeds,
          ratePercent: totalBeds > 0 ? Math.round((occupiedBeds / totalBeds) * 100) : 0,
        },
        activeDoctors,
        emergencyCases,
      },
      recentActivity: recentActivity.map((event) => ({
        id: event.id,
        patientMrn: event.patient.id,
        patientName: `${event.patient.name} ${event.patient.surname}`,
        eventTime: event.eventTime,
        description: event.eventDescription,
        createdAt: event.createdAt,
      })),
      timestamp: new Date().toISOString(),
    };
  }
}
