import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/stillpoint_mascot.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _buddyCtrl = TextEditingController(text: 'Pip');
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _buddyCtrl.dispose();
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
    final ok = await notifier.register(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
      buddyName: _buddyCtrl.text.trim().isEmpty ? 'Pip' : _buddyCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      // New account: onboarding is still to do (router sends them there).
      context.go('/onboarding');
      return;
    }
    final state = ref.read(authProvider);
    if (state.infoMessage != null) {
      _toast(state.infoMessage!, success: true);
      context.go('/login');
    } else {
      _toast(state.errorMessage ?? 'Registration failed');
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mascot
                const StillpointMascot(size: 72),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Create your account',
                  style: tt.headlineMedium?.copyWith(color: AppColors.lightTextPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your Still Point journey today',
                  style: tt.bodyMedium?.copyWith(color: AppColors.lightTextSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email (used to sign in)
                _StillPointField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Username
                _StillPointField(
                  controller: _usernameCtrl,
                  label: 'Username',
                  hint: 'choose_a_username',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    if (v.trim().contains(' ')) return 'No spaces allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Buddy name
                _StillPointField(
                  controller: _buddyCtrl,
                  label: "Your buddy's name",
                  hint: 'Pip',
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 14),

                // Password
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
                const SizedBox(height: 14),

                // Confirm password
                _StillPointField(
                  controller: _confirmCtrl,
                  label: 'Confirm password',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Create Account button (coral accent)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightAccent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.lightAccent.withOpacity(0.4),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign in link
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: tt.bodyMedium?.copyWith(color: AppColors.lightTextSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: tt.bodyMedium?.copyWith(
                            color: AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Data privacy note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightTextPrimary.withOpacity(0.04),
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.lightTextSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your data is stored securely on Supabase and used only for the Stride Probe research study.',
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.lightTextSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
