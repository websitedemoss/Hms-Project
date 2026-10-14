import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CreatePatientDto {
  @ApiProperty({ description: 'First name', example: 'Ramesh' })
  @IsString()
  @IsNotEmpty({ message: 'First name is required' })
  name: string;

  @ApiProperty({ description: 'Surname / Family name', example: 'Patel' })
  @IsString()
  @IsNotEmpty({ message: 'Surname is required' })
  surname: string;

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
}
