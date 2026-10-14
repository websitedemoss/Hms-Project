import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterHospitalDto } from './dto/register-hospital.dto';
import { JwtPayload } from './strategies/jwt.strategy';

const ALL_CLINICAL_PERMISSIONS = [
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

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * 1. Authenticate Staff User and Issue Dual Tokens (15m Access + 7d Refresh)
   */
  async login(dto: LoginDto) {
    const username = dto.username.trim();

    // 1. Lookup staff member by username (case-insensitive)
    const staff = await this.prisma.staff.findFirst({
      where: {
        username: { equals: username, mode: 'insensitive' },
      },
      include: {
        hospital: {
          select: {
            id: true,
            name: true,
            hospitalCode: true,
            tagline: true,
          },
        },
        permissions: {
          where: { permissionValue: true },
          select: { permissionKey: true },
        },
      },
    });

    if (!staff || !staff.isUser) {
      throw new UnauthorizedException('Invalid clinical credentials.');
    }

    if (staff.accountStatus !== 'Active') {
      throw new UnauthorizedException(
        `Staff account is currently ${staff.accountStatus}. Please contact Hospital Administration.`,
      );
    }

    // 2. Validate hospital code if specified
    if (dto.hospitalCode && staff.hospital.hospitalCode !== dto.hospitalCode.trim()) {
      throw new UnauthorizedException('Hospital organization code does not match this account.');
    }

    // 3. Verify Argon2id password hash
    if (!staff.passwordHash) {
      throw new UnauthorizedException('Account has not been configured with a security password.');
    }

    const isPasswordValid = await argon2.verify(staff.passwordHash, dto.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid clinical credentials.');
    }

    const activePermissions = staff.permissions.map((p) => p.permissionKey);

    // 4. Generate Tokens
    const { accessToken, refreshToken, expiresAt } = await this.generateTokens(staff, activePermissions);

    // 5. Store Refresh Token in DB for family rotation tracking
    await this.prisma.refreshToken.create({
      data: {
        token: refreshToken,
        staffId: staff.id,
        expiresAt,
        isRevoked: false,
      },
    });

    this.logger.log(`Staff login successful: ${staff.username} (${staff.role}) [Hospital: ${staff.hospital.name}]`);

    return {
      accessToken,
      refreshToken,
      user: {
        id: staff.id,
        staffCode: staff.staffCode,
        username: staff.username,
        firstName: staff.firstName,
        lastName: staff.lastName,
        email: staff.email,
        phone: staff.phone,
        role: staff.role,
        department: staff.department,
        avatarUrl: staff.avatarUrl,
        hospital: staff.hospital,
        permissions: activePermissions,
      },
    };
  }

  /**
   * 2. Refresh Access Token using Refresh Token with Family Rotation
   */
  async refresh(dto: RefreshTokenDto) {
    const { refreshToken } = dto;

    // Verify token cryptographic signature
    let decoded: any;
    try {
      decoded = this.jwtService.verify(refreshToken, {
        secret:
          this.configService.get<string>('JWT_REFRESH_SECRET') ||
          'hospital_jwt_refresh_secret_modernized_2026_super_secure_key_12345',
      });
    } catch {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    // Look up token in DB
    const dbToken = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: {
        staff: {
          include: {
            hospital: {
              select: {
                id: true,
                name: true,
                hospitalCode: true,
                tagline: true,
              },
            },
            permissions: {
              where: { permissionValue: true },
              select: { permissionKey: true },
            },
          },
        },
      },
    });

    if (!dbToken || dbToken.isRevoked || dbToken.expiresAt < new Date()) {
      // Possible token replay attack - revoke all active refresh tokens for this staff member
      if (dbToken && dbToken.isRevoked) {
        await this.prisma.refreshToken.updateMany({
          where: { staffId: dbToken.staffId },
          data: { isRevoked: true },
        });
        this.logger.warn(`Security warning: Replayed refresh token detected for staff ID ${dbToken.staffId}!`);
      }
      throw new UnauthorizedException('Refresh token revoked or expired. Please re-authenticate.');
    }

    const staff = dbToken.staff;
    if (staff.accountStatus !== 'Active') {
      throw new UnauthorizedException('Staff account has been deactivated.');
    }

    // Revoke old refresh token (family rotation)
    await this.prisma.refreshToken.update({
      where: { id: dbToken.id },
      data: { isRevoked: true },
    });

    const activePermissions = staff.permissions.map((p) => p.permissionKey);

    // Issue new token pair
    const tokens = await this.generateTokens(staff, activePermissions);

    // Store new refresh token
    await this.prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        staffId: staff.id,
        expiresAt: tokens.expiresAt,
        isRevoked: false,
      },
    });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: staff.id,
        staffCode: staff.staffCode,
        username: staff.username,
        firstName: staff.firstName,
        lastName: staff.lastName,
        email: staff.email,
        phone: staff.phone,
        role: staff.role,
        department: staff.department,
        avatarUrl: staff.avatarUrl,
        hospital: staff.hospital,
        permissions: activePermissions,
      },
    };
  }

  /**
   * 3. Terminate Session & Revoke Refresh Token
   */
  async logout(staffId: number, refreshToken?: string) {
    if (refreshToken) {
      await this.prisma.refreshToken.updateMany({
        where: { token: refreshToken },
        data: { isRevoked: true },
      });
    } else {
      // Revoke all tokens for this staff member
      await this.prisma.refreshToken.updateMany({
        where: { staffId },
        data: { isRevoked: true },
      });
    }

    return { message: 'Logged out successfully.' };
  }

  /**
   * 4. Retrieve Current Logged-in Staff Profile & Active Permissions
   */
  async getMe(staffId: number) {
    const staff = await this.prisma.staff.findUnique({
      where: { id: staffId },
      include: {
        hospital: {
          select: {
            id: true,
            name: true,
            hospitalCode: true,
            tagline: true,
            phone: true,
            email: true,
            address: true,
          },
        },
        permissions: {
          select: {
            permissionKey: true,
            permissionValue: true,
          },
        },
      },
    });

    if (!staff) {
      throw new NotFoundException('Staff account not found.');
    }

    const activePermissions = staff.permissions
      .filter((p) => p.permissionValue)
      .map((p) => p.permissionKey);

    return {
      id: staff.id,
      staffCode: staff.staffCode,
      username: staff.username,
      firstName: staff.firstName,
      lastName: staff.lastName,
      email: staff.email,
      phone: staff.phone,
      role: staff.role,
      department: staff.department,
      gender: staff.gender,
      shift: staff.shift,
      avatarUrl: staff.avatarUrl,
      accountStatus: staff.accountStatus,
      hospital: staff.hospital,
      permissions: activePermissions,
      allPermissionsMap: staff.permissions.reduce(
        (acc, p) => ({ ...acc, [p.permissionKey]: p.permissionValue }),
        {},
      ),
    };
  }

  /**
   * 5. Register New Hospital Tenant & Super Admin Account
   */
  async registerHospital(dto: RegisterHospitalDto) {
    // Check if hospital code already in use
    const existingHospital = await this.prisma.hospital.findUnique({
      where: { hospitalCode: dto.hospitalCode.trim().toUpperCase() },
    });
    if (existingHospital) {
      throw new ConflictException(`Hospital code ${dto.hospitalCode} is already registered.`);
    }

    // Check if admin username in use
    const existingUser = await this.prisma.staff.findUnique({
      where: { username: dto.adminUsername.trim() },
    });
    if (existingUser) {
      throw new ConflictException(`Username ${dto.adminUsername} is already registered.`);
    }

    // Hash admin password with Argon2id
    const passwordHash = await argon2.hash(dto.adminPassword);

    // Create hospital, admin user, permissions, and default departments in a single transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const hospital = await tx.hospital.create({
        data: {
          hospitalCode: dto.hospitalCode.trim().toUpperCase(),
          name: dto.hospitalName.trim(),
          tagline: dto.tagline || 'Excellence in Healthcare',
          phone: dto.phone,
          email: dto.adminEmail,
          address: dto.address,
        },
      });

      // Create Super Admin Staff
      const adminStaff = await tx.staff.create({
        data: {
          hospitalId: hospital.id,
          staffCode: 'STF-ADM-001',
          firstName: 'Hospital',
          lastName: 'Administrator',
          email: dto.adminEmail,
          phone: dto.phone,
          role: 'Super Admin',
          department: 'Administration',
          isUser: true,
          username: dto.adminUsername.trim(),
          passwordHash,
          accountStatus: 'Active',
        },
      });

      // Grant all permissions to Super Admin
      for (const permKey of ALL_CLINICAL_PERMISSIONS) {
        await tx.staffPermission.create({
          data: {
            staffId: adminStaff.id,
            permissionKey: permKey,
            permissionValue: true,
          },
        });
      }

      // Initialize default AI config
      await tx.aiConfig.create({
        data: {
          hospitalId: hospital.id,
          enabled: true,
          modelName: 'qwen2.5:3b',
          provider: 'ollama',
          apiUrl: 'http://localhost:11434',
        },
      });

      return { hospital, adminStaff };
    });

    this.logger.log(`New Hospital Onboarded: ${result.hospital.name} [Code: ${result.hospital.hospitalCode}]`);

    // Auto-login new admin
    return this.login({
      username: dto.adminUsername,
      password: dto.adminPassword,
      hospitalCode: result.hospital.hospitalCode,
    });
  }

  // ---------------- Private Helpers ----------------

  private async generateTokens(staff: any, permissions: string[]) {
    const payload: JwtPayload = {
      sub: staff.id,
      username: staff.username,
      hospitalId: staff.hospitalId,
      role: staff.role,
      permissions,
    };

    const accessSecret =
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      'hospital_jwt_access_secret_modernized_2026_super_secure_key_12345';
    const refreshSecret =
      this.configService.get<string>('JWT_REFRESH_SECRET') ||
      'hospital_jwt_refresh_secret_modernized_2026_super_secure_key_12345';

    const accessToken = this.jwtService.sign(payload, {
      secret: accessSecret,
      expiresIn: '15m',
    });

    const refreshToken = this.jwtService.sign(
      { sub: staff.id, username: staff.username },
      {
        secret: refreshSecret,
        expiresIn: '7d',
      },
    );

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    return { accessToken, refreshToken, expiresAt };
  }
}
