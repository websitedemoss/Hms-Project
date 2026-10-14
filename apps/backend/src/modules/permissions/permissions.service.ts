import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdatePermissionsDto } from './dto/update-permissions.dto';

export const ROLE_PRESETS: Record<string, string[]> = {
  'Super Admin': [
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
  Doctor: [
    'dashboard',
    'patients',
    'appointments',
    'queue',
    'bed',
    'medical_files',
    'bhooma_ai',
  ],
  Receptionist: [
    'dashboard',
    'patients',
    'appointments',
    'queue',
    'attendance',
  ],
  Nurse: [
    'dashboard',
    'patients',
    'appointments',
    'attendance',
    'bed',
    'medical_files',
  ],
};

@Injectable()
export class PermissionsService {
  private readonly logger = new Logger(PermissionsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Return standardized role presets
   */
  getRolePresets() {
    return {
      presets: ROLE_PRESETS,
      availableKeys: [
        { key: 'dashboard', label: 'Executive Dashboard & Live Stats', module: 'Analytics' },
        { key: 'patients', label: 'Patient Directory & Demographics', module: 'Patients' },
        { key: 'appointments', label: 'Appointment Scheduling & Slot Booking', module: 'Appointments' },
        { key: 'queue', label: 'Live Token Queue & Consultation Stepper', module: 'Clinical' },
        { key: 'doctors', label: 'Doctor Directory & Rosters', module: 'Administration' },
        { key: 'staff', label: 'Staff Registry & Access Control', module: 'Administration' },
        { key: 'attendance', label: 'Staff Attendance & Geofencing', module: 'Operations' },
        { key: 'bed', label: 'Ward & Inpatient Bed Management', module: 'Inpatient' },
        { key: 'medical_files', label: 'Medical Records, Scans & Cloud Storage', module: 'Medical Records' },
        { key: 'bhooma_ai', label: 'BHOOMA AI Clinical Assistant', module: 'AI & Automation' },
        { key: 'settings', label: 'Hospital Settings & System Configuration', module: 'Administration' },
      ],
    };
  }

  /**
   * Get permissions for a specific staff member
   */
  async getStaffPermissions(staffId: number) {
    const staff = await this.prisma.staff.findUnique({
      where: { id: staffId },
      include: {
        permissions: true,
      },
    });

    if (!staff) {
      throw new NotFoundException(`Staff member #${staffId} not found.`);
    }

    const permissionMap: Record<string, boolean> = {};
    staff.permissions.forEach((p) => {
      permissionMap[p.permissionKey] = p.permissionValue;
    });

    return {
      staffId: staff.id,
      staffName: `${staff.firstName} ${staff.lastName}`,
      username: staff.username,
      role: staff.role,
      department: staff.department,
      accountStatus: staff.accountStatus,
      permissions: permissionMap,
    };
  }

  /**
   * Update permissions and account status for a staff member
   */
  async updateStaffPermissions(
    staffId: number,
    dto: UpdatePermissionsDto,
    grantedById: number,
  ) {
    const staff = await this.prisma.staff.findUnique({
      where: { id: staffId },
    });

    if (!staff) {
      throw new NotFoundException(`Staff member #${staffId} not found.`);
    }

    // Update accountStatus if provided
    if (dto.accountStatus && dto.accountStatus !== staff.accountStatus) {
      await this.prisma.staff.update({
        where: { id: staffId },
        data: { accountStatus: dto.accountStatus },
      });
    }

    // Upsert permissions
    for (const [key, value] of Object.entries(dto.permissions)) {
      await this.prisma.staffPermission.upsert({
        where: {
          uq_staff_perm: {
            staffId,
            permissionKey: key,
          },
        },
        update: {
          permissionValue: value,
          grantedBy: grantedById,
          grantedAt: new Date(),
        },
        create: {
          staffId,
          permissionKey: key,
          permissionValue: value,
          grantedBy: grantedById,
        },
      });
    }

    this.logger.log(
      `Permissions updated for staff #${staffId} (${staff.username}) by staff #${grantedById}`,
    );

    return this.getStaffPermissions(staffId);
  }
}
