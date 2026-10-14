import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'Admin@1234');
  final _hospitalCodeController = TextEditingController(text: 'MEDICARE-01');
  bool _obscurePassword = true;
  bool _showHospitalCode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _hospitalCodeController.dispose();
    super.dispose();
  }

  void _applyQuickLogin(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
    _handleLogin();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          hospitalCode: _showHospitalCode ? _hospitalCodeController.text.trim() : null,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Soft slate background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: FadeSlideIn(
            duration: const Duration(milliseconds: 450),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // 1. Hospital Brand Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'MEDICARE HOSPITAL & I.C.U',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge(color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Clinical Operations & Hospital Management System',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 28),

                // 2. Authentication Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Clinical Staff Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your assigned healthcare credentials to continue.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error message banner
                        if (authState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username or Staff Code',
                            hintText: 'e.g. admin, dr.rajesh',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Optional Hospital Code Toggle
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _showHospitalCode = !_showHospitalCode),
                              icon: Icon(
                                _showHospitalCode
                                    ? Icons.arrow_drop_up_rounded
                                    : Icons.arrow_drop_down_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _showHospitalCode
                                    ? 'Hide Hospital Code'
                                    : 'Specify Organization Code (Optional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_showHospitalCode) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _hospitalCodeController,
                            decoration: InputDecoration(
                              labelText: 'Hospital Organization Code',
                              hintText: 'MEDICARE-01',
                              prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In to Workstation',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Quick 1-Click Test Accounts
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 6),
                          const Text(
                            'Quick Demo Roles (1-Click Test Access)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickRoleChip(
                            label: 'Super Admin',
                            sub: 'admin / 11 Perms',
                            color: Colors.blue.shade700,
                            onTap: () => _applyQuickLogin('admin', 'Admin@1234'),
                          ),
                          _QuickRoleChip(
                            label: 'Doctor',
                            sub: 'dr.rajesh / Clinical',
                            color: Colors.teal.shade700,
                            onTap: () => _applyQuickLogin('dr.rajesh', 'Doctor@1234'),
                          ),
                          _QuickRoleChip(
                            label: 'Reception',
                            sub: 'reception / Queue',
                            color: Colors.orange.shade800,
                            onTap: () => _applyQuickLogin('reception', 'Staff@1234'),
                          ),
                          _QuickRoleChip(
                            label: 'Nurse',
                            sub: 'nurse.sunita / Beds',
                            color: Colors.purple.shade700,
                            onTap: () => _applyQuickLogin('nurse.sunita', 'Staff@1234'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Compliance Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Stateless Dual-Token JWT • Argon2id Encryption • ABDM & DPDPA Ready',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _QuickRoleChip extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _QuickRoleChip({
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
