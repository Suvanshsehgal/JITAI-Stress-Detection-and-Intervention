import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/onboarding_provider.dart';
import 'widgets/step1_buddy.dart';
import 'widgets/step2_goals.dart';
import 'widgets/step3_data.dart';
import '../../shared/widgets/ebb_button.dart';
import '../../shared/widgets/ebb_orb.dart';
import '../../core/responsive/responsive_layout.dart';

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
    // Hide keyboard if open
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
        // Top section with orb and progress
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
          child: Column(
            children: [
              const EbbOrb(size: 80),
              const SizedBox(height: 24),
              _buildProgressIndicator(context),
            ],
          ),
        ),
        
        // Main scrollable content (PageView)
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
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
        
        // Bottom controls
        _buildBottomControls(context),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(13),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentIndex > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _isSaving ? null : _prevStep,
                  tooltip: 'Go Back',
                ),
              ),
            Expanded(
              child: EbbButton(
                label: _currentIndex == 2 ? 'Start learning my baseline' : 'Continue',
                onPressed: _nextStep,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
