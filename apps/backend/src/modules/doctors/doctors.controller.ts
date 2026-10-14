import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { DoctorsService } from './doctors.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Doctors')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('doctors')
export class DoctorsController {
  constructor(private readonly doctorsService: DoctorsService) {}

  @Get()
  @RequirePermissions('doctors')
  @ApiOperation({
    summary: 'List Doctors with Schedules',
    description: 'Retrieves all medical practitioners, specialty departments, and configured day schedules.',
  })
  @ApiResponse({ status: 200, description: 'List of doctors.' })
  async findMany(@CurrentUser() user: AuthenticatedUser) {
    return this.doctorsService.findMany(user.hospitalId);
  }

  @Get(':id/slots')
  @RequirePermissions('appointments')
  @ApiOperation({
    summary: 'Calculate Available Doctor Slots',
    description:
      'Dynamically checks configured time slots against existing booked appointments to prevent slot collision.',
  })
  @ApiResponse({ status: 200, description: 'Available slot schedule.' })
  async getAvailableSlots(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query('date') date: string,
  ) {
    const targetDate = date || new Date().toISOString().split('T')[0];
    return this.doctorsService.getAvailableSlots(user.hospitalId, id, targetDate);
  }

  @Get(':id')
  @RequirePermissions('doctors')
  @ApiOperation({
    summary: 'Get Doctor Profile',
    description: 'Returns doctor qualification, consultation fee, and roster.',
  })
  @ApiResponse({ status: 200, description: 'Doctor profile.' })
  async findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.doctorsService.findById(user.hospitalId, id);
  }
}
