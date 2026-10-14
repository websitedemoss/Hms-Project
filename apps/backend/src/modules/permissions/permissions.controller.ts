import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { PermissionsService } from './permissions.service';
import { UpdatePermissionsDto } from './dto/update-permissions.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { RequirePermissions } from '../auth/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Staff & Permissions')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('permissions')
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Get('presets')
  @ApiOperation({
    summary: 'Retrieve Role Preset Templates',
    description: 'Returns clinical role preset permission configurations (Doctor, Nurse, Receptionist, Admin).',
  })
  @ApiResponse({ status: 200, description: 'Role preset permissions map.' })
  getRolePresets() {
    return this.permissionsService.getRolePresets();
  }

  @Get(':staffId')
  @RequirePermissions('staff')
  @ApiOperation({
    summary: 'Get Staff Permissions',
    description: 'Returns the full 11-key permission matrix and account status for a given staff member.',
  })
  @ApiResponse({ status: 200, description: 'Staff permission details.' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires staff administrative permission.' })
  getStaffPermissions(@Param('staffId', ParseIntPipe) staffId: number) {
    return this.permissionsService.getStaffPermissions(staffId);
  }

  @Put(':staffId')
  @RequirePermissions('staff')
  @ApiOperation({
    summary: 'Update Staff Permissions Matrix',
    description: 'Updates active permission flags and account status (Active, Blocked, Suspended) for a staff member.',
  })
  @ApiResponse({ status: 200, description: 'Updated permissions matrix.' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires staff administrative permission.' })
  updateStaffPermissions(
    @Param('staffId', ParseIntPipe) staffId: number,
    @Body() dto: UpdatePermissionsDto,
    @CurrentUser() adminUser: AuthenticatedUser,
  ) {
    return this.permissionsService.updateStaffPermissions(staffId, dto, adminUser.id);
  }
}
