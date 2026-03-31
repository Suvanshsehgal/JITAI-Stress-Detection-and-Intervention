import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../widget/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // transparent
        statusBarIconBrightness: Brightness.light, // white icons (for brown bg)
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary, // brown top
        body: Column(
          children: [
            // 🔝 TOP SECTION
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: AppColors.primary,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: Image.asset(
                        'assets/images/onboard.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 🔽 BOTTOM SECTION
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Indicator
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Built With You, For You',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'We\'re building a JIT-AI based stress detection system to better understand and manage daily stress. Your participation helps us improve by getting accurate data about your own stress patterns.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary.withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    // Create Account
                    CustomButton(
                      text: 'Create an Account',
                      isPrimary: true,
                      onPressed: () {},
                    ),

                    const SizedBox(height: 16),

                    // Login
                    CustomButton(
                      text: 'Login',
                      isPrimary: false,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}