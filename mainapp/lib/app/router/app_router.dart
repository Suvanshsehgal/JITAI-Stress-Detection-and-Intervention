import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shared_prefs_provider.dart';
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
import '../../features/toolbox/history_screen.dart';
import '../../features/interventions/screens/intervention_detail_screen.dart';
import '../../features/interventions/screens/intervention_runner_router.dart';
import '../../features/interventions/screens/intervention_completion_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorBuddyKey = GlobalKey<NavigatorState>(debugLabel: 'buddy');
final _shellNavigatorToolboxKey = GlobalKey<NavigatorState>(debugLabel: 'toolbox');
final _shellNavigatorInsightsKey = GlobalKey<NavigatorState>(debugLabel: 'insights');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final prefs = ref.read(sharedPreferencesProvider);
      final isCompleted = prefs.getBool('onboardingCompleted') ?? false;
      final isOnboarding = state.uri.toString() == '/onboarding';

      if (!isCompleted && !isOnboarding) {
        return '/onboarding';
      }
      if (isCompleted && state.uri.toString() == '/') {
        return '/home';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: \${state.uri.toString()}')),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/intervention/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InterventionDetailScreen(interventionId: id);
        },
      ),
      GoRoute(
        path: '/intervention/:id/run',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InterventionRunnerRouter(interventionId: id);
        },
      ),
      GoRoute(
        path: '/intervention/:id/complete',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final startedAt = state.extra as DateTime? ?? DateTime.now();
          return InterventionCompletionScreen(interventionId: id, startedAt: startedAt);
        },
      ),
      GoRoute(
        path: '/health',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/garden',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GardenScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBuddyKey,
            routes: [
              GoRoute(
                path: '/buddy',
                builder: (context, state) => const BuddyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorToolboxKey,
            routes: [
              GoRoute(
                path: '/toolbox',
                builder: (context, state) => const ToolboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInsightsKey,
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
