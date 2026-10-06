import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/ebb_card.dart';
import '../insights/providers/baseline_provider.dart';
import '../jitai/providers/jitai_providers.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../sync/providers/sync_provider.dart';
import '../sync/services/sync_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);
    final baseline = ref.watch(baselineProvider);
    final authState = ref.watch(authProvider);
    final useRemoteBackend = ref.watch(useRemoteBackendProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
              EbbCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        ((authState.username != null && authState.username!.isNotEmpty)
                                ? authState.username![0]
                                : 'U')
                            .toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (authState.username != null && authState.username!.isNotEmpty)
                                ? authState.username!
                                : 'Guest User',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buddy: ${onboardingState.buddyName} (${onboardingState.tone.name})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cloud Sync & Backend Card
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_sync_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cloud & ML Integration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remote Backend & ML',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              useRemoteBackend
                                  ? 'Active (FastAPI + Stride ML)'
                                  : 'Offline / Mock Only',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: useRemoteBackend,
                          onChanged: (val) {
                            ref.read(useRemoteBackendProvider.notifier).state = val;
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interventions Database',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Supabase PostgreSQL sync',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: syncState == SyncStateStatus.syncing
                              ? null
                              : () async {
                                  final count = await ref
                                      .read(syncProvider.notifier)
                                      .syncNow();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          count > 0
                                              ? 'Synced $count intervention response(s) to cloud.'
                                              : 'All records are in sync.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                          icon: syncState == SyncStateStatus.syncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: Text(
                            syncState == SyncStateStatus.syncing
                                ? 'Syncing...'
                                : 'Sync Now',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Baseline & System Status
              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Intelligence',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrefRow(
                      theme,
                      'Baseline Learning',
                      baseline.progressPercent >= 1.0
                          ? 'Established'
                          : '${(baseline.progressPercent * 100).toInt()}% Complete',
                    ),
                    const Divider(height: 24),
                    _buildPrefRow(
                      theme,
                      'Cooldown Enforced',
                      '15 minutes between nudges',
                    ),
                    const Divider(height: 24),
                    _buildPrefRow(
                      theme,
                      'Calendar Shield',
                      'Suppresses nudges during meetings',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Link to Health & Context Screen
              EbbCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Health & Context Signals',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Manage wearable inputs & privacy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/health'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrefRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
