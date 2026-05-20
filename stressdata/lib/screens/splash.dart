import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/colors.dart';
import 'Login.dart';
import 'Register.dart';
import 'terms_conditions_screen.dart';
import '../widget/custom_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ✅ Lottie Animation (FIXED SIZE ISSUE)
              SizedBox(
                width: double.infinity,
                height: 300,
                child: Lottie.asset(
                  'assets/animations/Start1.json',
                  fit: BoxFit.cover, // 🔥 important fix
                  repeat: true,
                  animate: true,
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'STRIDE PROBE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'The first step to a stress-free you ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Login Button
              CustomButton(
                text: 'Login',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                isPrimary: true,
              ),

              const SizedBox(height: 12),

              // Signup Button
              CustomButton(
                text: 'Sign Up',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                isPrimary: false,
              ),

              const SizedBox(height: 16),

              // Terms & Conditions
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsConditionsScreen(),
                    ),
                  );
                },
                child: Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }
}