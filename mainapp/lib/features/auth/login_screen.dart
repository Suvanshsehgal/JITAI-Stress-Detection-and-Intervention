import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/stillpoint_mascot.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _toast(String text, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? AppColors.lightCalm : AppColors.lightRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authProvider.notifier);
    final ok = await notifier.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home'); // router sends to /onboarding if it is not finished
    } else {
      _toast(ref.read(authProvider).errorMessage ?? 'Sign in failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.lightPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Mascot
                const StillpointMascot(size: 80),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Welcome back',
                  style: tt.headlineMedium?.copyWith(color: AppColors.lightTextPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your journey',
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email field
                _StillPointField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                _StillPointField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBrand,
                      foregroundColor: AppColors.lightPage,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.lightBrand.withOpacity(0.4),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightPage,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.lightBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: tt.labelSmall?.copyWith(color: AppColors.lightTextSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.lightBorder)),
                  ],
                ),
                const SizedBox(height: 20),

                // Create account link
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: tt.bodyMedium?.copyWith(color: AppColors.lightTextSecondary),
                      children: [
                        TextSpan(
                          text: 'Create one',
                          style: tt.bodyMedium?.copyWith(
                            color: AppColors.lightAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.lightAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Continue as guest / offline mode
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).loginGuest();
                    if (context.mounted) context.go('/home');
                  },
                  child: Text(
                    'Explore as Guest (Offline Mode)',
                    style: tt.labelMedium?.copyWith(
                      color: AppColors.lightTextSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Backend status badge
                _BackendStatusBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Reusable text field styled to Still Point design
// ───────────────────────────────────────────────────────────────────────────
class _StillPointField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _StillPointField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: tt.bodyMedium?.copyWith(color: AppColors.lightTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.lightTextSecondary, size: 20),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.lightTextTertiary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.lightRose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.lightRose, width: 1.5),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Small badge indicating backend connectivity
// ───────────────────────────────────────────────────────────────────────────
class _BackendStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightCalmSoft,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFBCE0CF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cloud_outlined, size: 14, color: AppColors.lightCalm),
          SizedBox(width: 6),
          Text(
            'Secured by Supabase',
            style: TextStyle(
              color: AppColors.lightCalm,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
