import {
  Controller,
  Get,
  Post,
  Param,
  Body,
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
import { ConsultationsService } from './consultations.service';
import { SaveConsultationDto } from './dto/save-consultation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Clinical Consultations')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('consultations')
export class ConsultationsController {
  constructor(private readonly consultationsService: ConsultationsService) {}

  @Get(':appointmentId')
  @RequirePermissions('queue')
  @ApiOperation({
    summary: 'Get Consultation Details',
    description: 'Retrieves diagnoses, Latin-translated prescriptions, and disposition records for an appointment.',
  })
  @ApiResponse({ status: 200, description: 'Consultation records.' })
  async getConsultation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.consultationsService.getConsultation(user.hospitalId, appointmentId);
  }

  @Post(':appointmentId')
  @RequirePermissions('queue')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Save 4-Step Clinical Consultation',
    description:
      'Commits diagnoses (ICD-10), prescriptions (Latin parsed), bed admission/disposition, and timeline records transactionally.',
  })
  @ApiResponse({ status: 200, description: 'Consultation saved and appointment concluded.' })
  async saveConsultation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @Body() dto: SaveConsultationDto,
  ) {
    return this.consultationsService.saveConsultation(user.hospitalId, appointmentId, dto);
  }
}
