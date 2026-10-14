import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PrismaService } from '../../prisma/prisma.service';

@ApiTags('System Health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'System Health & PostgreSQL Ping' })
  @ApiResponse({ status: 200, description: 'Application and Database are healthy' })
  async checkHealth() {
    const startTime = Date.now();
    let dbStatus = 'disconnected';
    let dbError: string | null = null;
    let hospitalCount = 0;

    try {
      hospitalCount = await this.prisma.hospital.count();
      dbStatus = 'connected';
    } catch (err: any) {
      dbError = err?.message || 'Database query failed';
    }

    const latencyMs = Date.now() - startTime;

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
      database: {
        status: dbStatus,
        latencyMs,
        hospitalsRegistered: hospitalCount,
        error: dbError,
      },
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
    };
  }
}
