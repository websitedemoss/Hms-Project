import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateAppointmentDto {
  @ApiProperty({ description: 'Patient MRN (e.g. CP-2026-001)', example: 'CP-2026-001' })
  @IsString()
  @IsNotEmpty({ message: 'Patient MRN is required' })
  patientId: string;

  @ApiProperty({ description: 'Doctor ID (e.g. DOC001)', example: 'DOC001' })
  @IsString()
  @IsNotEmpty({ message: 'Doctor ID is required' })
  doctorId: string;

  @ApiProperty({ description: 'Appointment date in YYYY-MM-DD format', example: '2026-10-14' })
  @IsDateString({}, { message: 'Must be a valid ISO date (YYYY-MM-DD)' })
  date: string;

  @ApiProperty({ description: 'Selected time slot (e.g. 10:30 AM)', example: '10:30 AM' })
  @IsString()
  @IsNotEmpty({ message: 'Time slot is required' })
  slot: string;

  @ApiPropertyOptional({ description: 'Consultation type', example: 'General Consultation' })
  @IsString()
  @IsOptional()
  type?: string;

  @ApiPropertyOptional({ description: 'Patient chief complaints / symptoms', example: 'Mild chest tightness' })
  @IsString()
  @IsOptional()
  symptoms?: string;

  @ApiPropertyOptional({ description: 'Known allergies', example: 'Penicillin' })
  @IsString()
  @IsOptional()
  allergies?: string;

  @ApiPropertyOptional({ description: 'Booking channel', example: 'walk-in', enum: ['walk-in', 'online', 'referral'] })
  @IsString()
  @IsOptional()
  @IsIn(['walk-in', 'online', 'referral'])
  bookingType?: string;
}
