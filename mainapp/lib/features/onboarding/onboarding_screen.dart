import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/onboarding_provider.dart';
import 'widgets/step1_buddy.dart';
import 'widgets/step2_goals.dart';
import 'widgets/step3_data.dart';
import '../../shared/widgets/ebb_button.dart';
import '../../shared/widgets/stillpoint_mascot.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../app/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSaving = false;

  void _nextStep() async {
    FocusScope.of(context).unfocus();

    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      await ref.read(onboardingProvider.notifier).completeOnboarding();

      if (mounted) {
        context.go('/home');
      }
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex > 0) {
          _prevStep();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildContent(context),
            tablet: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // Top section with Mascot and progress
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: Column(
            children: [
              const StillpointMascot(size: 84),
              const SizedBox(height: 16),
              _buildProgressIndicator(context),
            ],
          ),
        ),

        // Page view for steps
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              Step1Buddy(),
              Step2Goals(),
              Step3Data(),
            ],
          ),
        ),

        // Bottom navigation buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: EbbButton(
                      label: 'Back',
                      isSecondary: true,
                      onPressed: _prevStep,
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: EbbButton(
                  label: _currentIndex == 2 ? 'Get Started' : 'Continue',
                  isLoading: _isSaving,
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive ? AppColors.lightBrand : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}
