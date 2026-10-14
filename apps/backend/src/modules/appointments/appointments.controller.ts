import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStageDto } from './dto/update-stage.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Appointments & Queue')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Get('queue')
  @RequirePermissions('queue')
  @ApiOperation({
    summary: 'Live Patient Triage Queue',
    description: 'Retrieves today live clinic queue grouped into 4 progression stages with token numbers.',
  })
  @ApiResponse({ status: 200, description: 'Live queue data.' })
  async getQueue(
    @CurrentUser() user: AuthenticatedUser,
    @Query('date') date?: string,
  ) {
    return this.appointmentsService.getQueue(user.hospitalId, date);
  }

  @Get()
  @RequirePermissions('appointments')
  @ApiOperation({
    summary: 'List Appointments',
    description: 'Filter scheduled appointments by date, doctor, or status.',
  })
  @ApiResponse({ status: 200, description: 'List of appointments.' })
  async findMany(
    @CurrentUser() user: AuthenticatedUser,
    @Query('date') date?: string,
    @Query('doctorId') doctorId?: string,
    @Query('status') status?: string,
    @Query('patientId') patientId?: string,
  ) {
    return this.appointmentsService.findMany(user.hospitalId, { date, doctorId, status, patientId });
  }

  @Get(':id')
  @RequirePermissions('appointments')
  @ApiOperation({
    summary: 'Get Appointment by ID',
    description: 'Returns appointment clinical details with patient and doctor mappings.',
  })
  @ApiResponse({ status: 200, description: 'Appointment details.' })
  async findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.appointmentsService.findById(user.hospitalId, id);
  }

  @Post()
  @RequirePermissions('appointments')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Book Appointment with Anti-Collision Check',
    description: 'Allocates sequential token number, locks doctor time-slot, and records booking.',
  })
  @ApiResponse({ status: 201, description: 'Appointment booked successfully.' })
  @ApiResponse({ status: 409, description: 'Doctor slot conflict / already booked.' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.create(user.hospitalId, dto, user.id);
  }

  @Patch(':id/stage')
  @RequirePermissions('queue')
  @ApiOperation({
    summary: 'Update Queue Triage Stage',
    description: 'Advances patient along the queue progression stages (1: Waiting -> 2: In-Consultation -> 3: Observation -> 4: Completed).',
  })
  @ApiResponse({ status: 200, description: 'Queue stage updated.' })
  async updateStage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateStageDto,
  ) {
    return this.appointmentsService.updateStage(user.hospitalId, id, dto);
  }
}
