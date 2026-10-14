import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({
    description: 'Staff username (e.g. admin, dr.rajesh, reception, nurse.sunita)',
    example: 'admin',
  })
  @IsString()
  @IsNotEmpty({ message: 'Username is required' })
  username: string;

  @ApiProperty({
    description: 'Account password',
    example: 'Admin@1234',
  })
  @IsString()
  @IsNotEmpty({ message: 'Password is required' })
  @MinLength(6, { message: 'Password must be at least 6 characters' })
  password: string;

  @ApiPropertyOptional({
    description: 'Optional Hospital Code (defaults to MEDICARE-01 if omitted)',
    example: 'MEDICARE-01',
  })
  @IsString()
  @IsOptional()
  hospitalCode?: string;
}
