import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Dashboard & Analytics')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('overview')
  @RequirePermissions('dashboard')
  @ApiOperation({
    summary: 'Executive Hospital KPI Overview',
    description: 'Retrieves aggregated real-time operational indicators including bed occupancy, triage queue, and activity streams.',
  })
  @ApiResponse({ status: 200, description: 'Live KPI overview.' })
  async getOverview(@CurrentUser() user: AuthenticatedUser) {
    return this.dashboardService.getOverview(user.hospitalId);
  }
}
