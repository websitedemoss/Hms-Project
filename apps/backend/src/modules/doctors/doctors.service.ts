import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DoctorsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. List all active Doctors for hospital tenant with departments
   */
  async findMany(hospitalId: number) {
    return this.prisma.doctor.findMany({
      where: { hospitalId },
      include: {
        department: {
          select: { id: true, name: true, icon: true },
        },
        daySchedules: {
          where: { isAvailable: true },
          orderBy: { id: 'asc' },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  /**
   * 2. Find Single Doctor by ID
   */
  async findById(hospitalId: number, id: string) {
    const doctor = await this.prisma.doctor.findFirst({
      where: { id, hospitalId },
      include: {
        department: true,
        daySchedules: true,
        slots: true,
      },
    });

    if (!doctor) {
      throw new NotFoundException(`Doctor #${id} not found.`);
    }

    return doctor;
  }

  /**
   * 3. Compute Available Time Slots for Doctor on a specific Date
   * (Cross-references configured slots against existing booked appointments to prevent collisions)
   */
  async getAvailableSlots(hospitalId: number, doctorId: string, dateStr: string) {
    const doctor = await this.findById(hospitalId, doctorId);

    // 1. Get standard doctor slots
    const standardSlots = await this.prisma.doctorSlot.findMany({
      where: { doctorId },
      orderBy: { id: 'asc' },
    });

    const slotsList = standardSlots.length > 0
      ? standardSlots.map((s) => s.timeSlot)
      : [
          '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
          '05:00 PM', '05:30 PM', '06:00 PM', '06:30 PM',
        ];

    // 2. Fetch existing appointments for this doctor on this date
    const queryDate = new Date(dateStr);
    queryDate.setHours(0, 0, 0, 0);

    const bookedAppointments = await this.prisma.appointment.findMany({
      where: {
        hospitalId,
        doctorId,
        date: queryDate,
        status: { notIn: ['Cancelled', 'No-Show'] },
      },
      select: {
        slot: true,
        tokenNumber: true,
      },
    });

    const bookedSlotsSet = new Set(bookedAppointments.map((a) => a.slot));

    const slotAvailability = slotsList.map((slot) => {
      const isBooked = bookedSlotsSet.has(slot);
      return {
        slot,
        isAvailable: !isBooked,
        status: isBooked ? 'Booked' : 'Available',
      };
    });

    return {
      doctorId: doctor.id,
      doctorName: doctor.name,
      department: doctor.department?.name,
      consultationFee: doctor.consultationFee,
      date: dateStr,
      totalSlots: slotsList.length,
      availableCount: slotAvailability.filter((s) => s.isAvailable).length,
      slots: slotAvailability,
    };
  }
}
