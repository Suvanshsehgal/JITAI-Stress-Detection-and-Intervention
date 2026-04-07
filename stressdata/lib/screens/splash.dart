import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/colors.dart';
import 'onboarding.dart';
import 'data_consent_screen.dart';
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
                  color: AppColors.primary.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          DataConsentScreen(
                            onComplete: () {},
                          ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                  
                  if (result == true && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  }
                },
                isPrimary: true,
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
    ),
    );
  }
}