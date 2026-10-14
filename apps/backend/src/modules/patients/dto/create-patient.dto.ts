import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CreatePatientDto {
  @ApiPropertyOptional({ description: 'First name', example: 'Ramesh' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ description: 'First name alias', example: 'Ramesh' })
  @IsString()
  @IsOptional()
  firstName?: string;

  @ApiPropertyOptional({ description: 'Surname / Family name', example: 'Patel' })
  @IsString()
  @IsOptional()
  surname?: string;

  @ApiPropertyOptional({ description: 'Last name alias', example: 'Patel' })
  @IsString()
  @IsOptional()
  lastName?: string;

  @ApiPropertyOptional({ description: 'Date of birth', example: '1990-01-01' })
  @IsString()
  @IsOptional()
  dateOfBirth?: string;

  @ApiPropertyOptional({ description: 'Emergency contact object' })
  @IsOptional()
  emergencyContact?: any;

  @ApiPropertyOptional({ description: "Father's or Spouse's name", example: 'Harishbhai Patel' })
  @IsString()
  @IsOptional()
  fatherName?: string;

  @ApiPropertyOptional({ description: 'Contact phone number', example: '+91 98250 12345' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ description: 'Age in years', example: 54 })
  @IsInt()
  @Min(0)
  @Max(130)
  @IsOptional()
  age?: number;

  @ApiPropertyOptional({ description: 'Biological gender', example: 'Male', enum: ['Male', 'Female', 'Other'] })
  @IsString()
  @IsOptional()
  gender?: string;

  @ApiPropertyOptional({ description: 'Blood group', example: 'B+', enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] })
  @IsString()
  @IsOptional()
  bloodGroup?: string;

  @ApiPropertyOptional({ description: 'Emergency contact person', example: 'Geeta Patel (Wife)' })
  @IsString()
  @IsOptional()
  emergencyContactName?: string;

  @ApiPropertyOptional({ description: 'Emergency contact phone', example: '+91 98250 12346' })
  @IsString()
  @IsOptional()
  emergencyContactPhone?: string;

  @ApiPropertyOptional({ description: 'Email address' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Residential address' })
  @IsString()
  @IsOptional()
  address?: string;
}
