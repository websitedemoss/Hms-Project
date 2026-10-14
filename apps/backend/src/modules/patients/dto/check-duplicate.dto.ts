import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CheckDuplicatePatientDto {
  @ApiProperty({ description: 'First name', example: 'Ramesh' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: 'Surname', example: 'Patel' })
  @IsString()
  @IsNotEmpty()
  surname: string;

  @ApiPropertyOptional({ description: 'Phone number', example: '+91 98250 12345' })
  @IsString()
  @IsOptional()
  phone?: string;
}
