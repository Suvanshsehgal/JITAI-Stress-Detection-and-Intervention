import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/buddy/buddy_screen.dart';
import '../../features/toolbox/toolbox_screen.dart';
import '../../features/sos/sos_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/garden/garden_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: \${state.uri.toString()}')),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/buddy',
        builder: (context, state) => const BuddyScreen(),
      ),
      GoRoute(
        path: '/toolbox',
        builder: (context, state) => const ToolboxScreen(),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/garden',
        builder: (context, state) => const GardenScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
