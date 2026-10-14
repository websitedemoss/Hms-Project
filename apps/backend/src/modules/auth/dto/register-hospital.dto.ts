import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterHospitalDto {
  @ApiProperty({
    description: 'Hospital institution display name',
    example: 'Apex Multi-Speciality Hospital & Research Center',
  })
  @IsString()
  @IsNotEmpty()
  hospitalName: string;

  @ApiProperty({
    description: 'Unique hospital identifier code',
    example: 'APEX-01',
  })
  @IsString()
  @IsNotEmpty()
  hospitalCode: string;

  @ApiPropertyOptional({
    description: 'Hospital tagline or motto',
    example: 'Excellence in Tertiary Healthcare',
  })
  @IsString()
  @IsOptional()
  tagline?: string;

  @ApiProperty({
    description: 'Hospital Super Administrator username',
    example: 'apex_admin',
  })
  @IsString()
  @IsNotEmpty()
  adminUsername: string;

  @ApiProperty({
    description: 'Super Administrator secure password',
    example: 'Admin@Secure2026',
  })
  @IsString()
  @MinLength(8, { message: 'Admin password must be at least 8 characters' })
  adminPassword: string;

  @ApiProperty({
    description: 'Administrator contact email',
    example: 'admin@apexhospital.org',
  })
  @IsEmail({}, { message: 'Must be a valid email address' })
  adminEmail: string;

  @ApiPropertyOptional({
    description: 'Hospital emergency phone number',
    example: '+91 98250 99999',
  })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({
    description: 'Physical campus address',
    example: '45 Ring Road, Medical Hub, Ahmedabad, Gujarat',
  })
  @IsString()
  @IsOptional()
  address?: string;
}
