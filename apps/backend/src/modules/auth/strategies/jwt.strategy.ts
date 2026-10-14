import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../prisma/prisma.service';

export interface JwtPayload {
  sub: number;
  username: string;
  hospitalId: number;
  role: string;
  permissions?: string[];
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        configService.get<string>('JWT_ACCESS_SECRET') ||
        'hospital_jwt_access_secret_modernized_2026_super_secure_key_12345',
    });
  }

  async validate(payload: JwtPayload) {
    const staff = await this.prisma.staff.findUnique({
      where: { id: payload.sub },
      include: {
        permissions: {
          where: { permissionValue: true },
          select: { permissionKey: true },
        },
      },
    });

    if (!staff || !staff.isUser || staff.accountStatus !== 'Active') {
      throw new UnauthorizedException('User session is invalid or account has been deactivated.');
    }

    const activePermissions = staff.permissions.map((p) => p.permissionKey);

    return {
      id: staff.id,
      username: staff.username,
      staffCode: staff.staffCode,
      firstName: staff.firstName,
      lastName: staff.lastName,
      role: staff.role,
      department: staff.department,
      hospitalId: staff.hospitalId,
      permissions: activePermissions,
    };
  }
}
