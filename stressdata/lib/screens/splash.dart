import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'LOREM IPSUM',
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
                'Lorem ipsum Lorem ipsum Lorem ipsum Lorem ipsum Lorem ipsum',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to next screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy & Policy
              TextButton(
                onPressed: () {
                  // TODO: Navigate to privacy policy
                },
                child: Text(
                  'Privacy & Policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}