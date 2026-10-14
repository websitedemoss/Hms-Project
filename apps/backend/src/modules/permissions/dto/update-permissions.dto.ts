import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export class UpdatePermissionsDto {
  @ApiProperty({
    description: 'Map of permission keys to boolean enabled status',
    example: {
      dashboard: true,
      patients: true,
      appointments: true,
      queue: true,
      doctors: false,
      staff: false,
      attendance: true,
      bed: true,
      medical_files: true,
      bhooma_ai: false,
      settings: false,
    },
  })
  @IsObject()
  @IsNotEmpty()
  permissions: Record<string, boolean>;

  @ApiPropertyOptional({
    description: 'Account operational status',
    enum: ['Active', 'Blocked', 'Suspended'],
    example: 'Active',
  })
  @IsString()
  @IsOptional()
  @IsIn(['Active', 'Blocked', 'Suspended'])
  accountStatus?: string;
}
