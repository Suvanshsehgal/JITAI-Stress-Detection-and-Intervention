import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shared_prefs_provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/screens/score_breakdown_screen.dart';
import '../../features/buddy/buddy_screen.dart';
import '../../features/toolbox/toolbox_screen.dart';
import '../../features/sos/sos_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/screens/goals_badges_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/health/screens/watch_connect_screen.dart';
import '../../features/garden/garden_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/screens/nudge_settings_screen.dart';
import '../../features/support/support_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final prefs = ref.read(sharedPreferencesProvider);
      final isCompleted = prefs.getBool('onboardingCompleted') ?? false;
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;

      final loc = state.uri.toString();
      final isAuthRoute = loc == '/login' || loc == '/signup';
      final isOnboarding = loc == '/onboarding';

      // 1. Not authenticated → go to login (unless already on auth/onboarding routes)
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // 2. Authenticated but onboarding not done → go to onboarding
      if (isAuthenticated && !isCompleted && !isOnboarding && !isAuthRoute) {
        return '/onboarding';
      }

      // 3. Authenticated + onboarding done → redirect root to home
      if (isAuthenticated && isCompleted && loc == '/') {
        return '/home';
      }

      // 4. Already authenticated → don't show login/signup
      if (isAuthenticated && isAuthRoute) {
        return isCompleted ? '/home' : '/onboarding';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
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
        path: '/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/score-breakdown',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScoreBreakdownScreen(),
      ),
      GoRoute(
        path: '/journal',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/nudge-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NudgeSettingsScreen(),
      ),
      GoRoute(
        path: '/goals-badges',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GoalsBadgesScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
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
        path: '/watch',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WatchConnectScreen(),
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
        ],
      ),
    ],
  );
});
