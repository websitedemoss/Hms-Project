import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class DiagnosisItemDto {
  @ApiPropertyOptional({ description: 'ICD-10 classification code', example: 'I10' })
  @IsString()
  @IsOptional()
  icd10Code?: string;

  @ApiProperty({ description: 'Clinical diagnosis description', example: 'Essential Primary Hypertension' })
  @IsString()
  @IsNotEmpty()
  description: string;
}

export class PrescriptionItemDto {
  @ApiProperty({ description: 'Medicine brand or generic name', example: 'Tab. Telmisartan 40mg' })
  @IsString()
  @IsNotEmpty()
  medicineName: string;

  @ApiProperty({ description: 'Dosage quantity', example: '1 Tab' })
  @IsString()
  @IsNotEmpty()
  dosage: string;

  @ApiProperty({ description: 'Dosing frequency (e.g. TID, BID, OD, QID, HS, SOS)', example: 'OD' })
  @IsString()
  @IsNotEmpty()
  frequency: string;

  @ApiProperty({ description: 'Duration of course', example: '30 Days' })
  @IsString()
  @IsNotEmpty()
  duration: string;

  @ApiPropertyOptional({ description: 'Special patient instructions', example: 'After breakfast with water' })
  @IsString()
  @IsOptional()
  instructions?: string;
}

export class SaveConsultationDto {
  @ApiProperty({ description: 'Step 1: Clinical Diagnoses', type: [DiagnosisItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DiagnosisItemDto)
  diagnoses: DiagnosisItemDto[];

  @ApiProperty({ description: 'Step 2: Medicine Prescriptions', type: [PrescriptionItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PrescriptionItemDto)
  prescriptions: PrescriptionItemDto[];

  @ApiProperty({
    description: 'Step 3: Clinical Disposition',
    example: 'Discharged',
    enum: ['Discharged', 'Waiting for Reports', 'Admitted to Ward', 'Admitted to ICU'],
  })
  @IsString()
  @IsNotEmpty()
  disposition: string;

  @ApiPropertyOptional({ description: 'Assigned bed number if admitted', example: 'ICU-02' })
  @IsString()
  @IsOptional()
  bedNumber?: string;

  @ApiPropertyOptional({ description: 'Diagnostic lab tests ordered', example: 'CBC, Lipid Profile, ECG' })
  @IsString()
  @IsOptional()
  labTests?: string;

  @ApiPropertyOptional({ description: 'Step 4: Clinical Advice & Summary Notes', example: 'Follow low sodium diet. Return in 7 days.' })
  @IsString()
  @IsOptional()
  doctorNotes?: string;
}
