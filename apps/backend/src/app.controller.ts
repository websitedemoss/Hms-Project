import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Root')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'API Root Information' })
  getHello(): { message: string; version: string; docs: string } {
    return {
      message: 'Medicare Hospital Management System Modernized REST API',
      version: '1.0.0',
      docs: '/api/docs',
    };
  }
}
