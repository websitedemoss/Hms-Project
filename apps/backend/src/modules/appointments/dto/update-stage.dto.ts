import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateStageDto {
  @ApiProperty({ description: 'New queue triage stage (1: Waiting, 2: In-Consultation, 3: Tests/Observation, 4: Completed, 5: Discharged)', example: 2 })
  @IsInt()
  @Min(0)
  @Max(5)
  stage: number;

  @ApiPropertyOptional({ description: 'New appointment status', example: 'In-Consultation' })
  @IsString()
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ description: 'Clinical doctor notes or stage notes' })
  @IsString()
  @IsOptional()
  doctorNotes?: string;
}
