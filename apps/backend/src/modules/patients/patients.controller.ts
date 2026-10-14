import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { PatientsService } from './patients.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { CheckDuplicatePatientDto } from './dto/check-duplicate.dto';
import { PatientQueryDto } from './dto/patient-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Patients')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('patients')
export class PatientsController {
  constructor(private readonly patientsService: PatientsService) {}

  @Get()
  @RequirePermissions('patients')
  @ApiOperation({
    summary: 'Search & List Patients',
    description: 'Paginated patient directory with multi-column full-text search across MRN, name, and phone.',
  })
  @ApiResponse({ status: 200, description: 'Paginated patient directory.' })
  async findMany(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: PatientQueryDto,
  ) {
    return this.patientsService.findMany(user.hospitalId, query);
  }

  @Post('check-duplicate')
  @RequirePermissions('patients')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Duplicate Patient Verification',
    description: 'Checks whether an existing patient matches the given name, surname, or phone number.',
  })
  @ApiResponse({ status: 200, description: 'Duplicate check results.' })
  async checkDuplicate(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CheckDuplicatePatientDto,
  ) {
    return this.patientsService.checkDuplicate(user.hospitalId, dto);
  }

  @Get(':id/dossier')
  @RequirePermissions('patients')
  @ApiOperation({
    summary: 'Get Full Clinical Dossier',
    description: 'Returns the complete patient longitudinal record including visits, diagnoses, prescriptions, and files.',
  })
  @ApiResponse({ status: 200, description: 'Complete clinical dossier.' })
  async getDossier(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.patientsService.getDossier(user.hospitalId, id);
  }

  @Get(':id')
  @RequirePermissions('patients')
  @ApiOperation({
    summary: 'Get Patient Demographics',
    description: 'Returns patient profile details by clinical MRN.',
  })
  @ApiResponse({ status: 200, description: 'Patient demographic details.' })
  async findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.patientsService.findById(user.hospitalId, id);
  }

  @Post()
  @RequirePermissions('patients')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Register New Patient',
    description: 'Assigns next sequential MRN (CP-YYYY-XXX), creates permanent QR UUID token, and registers patient.',
  })
  @ApiResponse({ status: 201, description: 'Patient created successfully.' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePatientDto,
  ) {
    return this.patientsService.create(user.hospitalId, dto);
  }

  @Put(':id')
  @RequirePermissions('patients')
  @ApiOperation({
    summary: 'Update Patient Profile',
    description: 'Modifies patient demographic details.',
  })
  @ApiResponse({ status: 200, description: 'Patient profile updated.' })
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: Partial<CreatePatientDto>,
  ) {
    return this.patientsService.update(user.hospitalId, id, dto);
  }
}
