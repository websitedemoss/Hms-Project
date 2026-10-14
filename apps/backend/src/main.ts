import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // 1. Global API Prefix
  app.setGlobalPrefix('api/v1');

  // 2. Global Validation Pipe with strict whitelisting
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // 3. Global Exception Filter & Response Transform Interceptor
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new TransformInterceptor());

  // 4. CORS Configuration
  const allowedOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',')
    : ['http://localhost:3000', 'http://localhost:8080'];

  app.enableCors({
    origin: (origin, callback) => {
      // Allow mobile apps, curl, or matching web origins
      if (!origin || allowedOrigins.includes(origin) || origin.startsWith('http://localhost:')) {
        callback(null, true);
      } else {
        callback(null, true); // Permissive in development
      }
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type, Accept, Authorization, X-Requested-With',
  });

  // 5. Swagger / OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('Hospital Management System API')
    .setDescription(
      'Modernized Clinical API v1 for Hospital Management System — Supporting Flutter Web & Android APK',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT access token',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('System Health', 'Liveness ping and PostgreSQL connectivity status')
    .addTag('Authentication', 'Dual-token JWT login, refresh, profile, and MFA')
    .addTag('Patients', 'Patient registry, demographics, and QR cards')
    .addTag('Appointments', 'Booking, slots, daily schedules, and live token queues')
    .addTag('Clinical Consultations', 'Diagnoses, prescriptions, and timeline events')
    .addTag('Inpatient Beds', 'ICU, General Ward, and Private Room tracking')
    .addTag('Medical Files', 'Private S3 / Supabase signed URL uploads & audit logs')
    .addTag('Staff & Attendance', 'Staff registry, geofencing, and selfie attendance')
    .addTag('BHOOMA AI', 'Clinical assistant, Ollama tool-calling, and pending actions')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');

  logger.log(`=======================================================`);
  logger.log(`🏥 HMS Backend API running on: http://localhost:${port}/api/v1`);
  logger.log(`📚 Swagger Documentation on:    http://localhost:${port}/api/docs`);
  logger.log(`💓 Health Ping endpoint:       http://localhost:${port}/api/v1/health`);
  logger.log(`=======================================================`);
}

bootstrap();
