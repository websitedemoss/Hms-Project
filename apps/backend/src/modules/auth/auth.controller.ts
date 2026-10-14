import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterHospitalDto } from './dto/register-hospital.dto';
import { Public } from './decorators/public.decorator';
import { CurrentUser, AuthenticatedUser } from './decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Authenticate Staff User',
    description:
      'Validates staff credentials via Argon2id hash and issues 15-minute Access Token and 7-day Refresh Token.',
  })
  @ApiResponse({ status: 200, description: 'Authentication successful with dual tokens and profile.' })
  @ApiResponse({ status: 401, description: 'Invalid username/password or deactivated account.' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Refresh Access Token',
    description:
      'Exchanges a valid 7-day refresh token for a newly generated access token and rotated refresh token.',
  })
  @ApiResponse({ status: 200, description: 'Tokens successfully refreshed.' })
  @ApiResponse({ status: 401, description: 'Invalid, expired, or replayed refresh token.' })
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Revoke User Session',
    description: 'Revokes the current refresh token and invalidates active session state.',
  })
  @ApiResponse({ status: 200, description: 'Logged out successfully.' })
  async logout(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto?: Partial<RefreshTokenDto>,
  ) {
    return this.authService.logout(user.id, dto?.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Get('me')
  @ApiOperation({
    summary: 'Retrieve Current Staff Profile & Active Permissions',
    description:
      'Returns the full authenticated clinical user profile, tenant hospital details, and granted permission map.',
  })
  @ApiResponse({ status: 200, description: 'Current profile retrieved.' })
  @ApiResponse({ status: 401, description: 'Unauthorized / expired JWT token.' })
  async getMe(@CurrentUser() user: AuthenticatedUser) {
    return this.authService.getMe(user.id);
  }

  @Public()
  @Post('register-hospital')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Register New Hospital Organization',
    description:
      'Onboards a new hospital tenant, seeds core configuration, and provisions the initial Super Administrator account.',
  })
  @ApiResponse({ status: 201, description: 'Hospital organization successfully registered.' })
  @ApiResponse({ status: 409, description: 'Hospital code or administrator username already exists.' })
  async registerHospital(@Body() dto: RegisterHospitalDto) {
    return this.authService.registerHospital(dto);
  }
}
