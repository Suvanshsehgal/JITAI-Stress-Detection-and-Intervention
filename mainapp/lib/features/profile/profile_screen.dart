import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/ebb_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    final userName = (authState.username != null && authState.username!.isNotEmpty)
        ? authState.username!
        : 'Aarav Mehta';

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA68C8), Color(0xFFF48FB1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA68C8).withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                userName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Using Stillpoint since Oct 2026',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Study linked badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: AppColors.lightCalm, size: 8),
                    SizedBox(width: 8),
                    Text(
                      'Linked to StressLab P-0142',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row (Avg score, Best streak, Resets tried)
              EbbCard(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('38', 'Avg score', AppColors.lightAccent),
                    Container(height: 36, width: 1, color: AppColors.lightBorder),
                    _buildStatColumn('9', 'Best streak', AppColors.lightAccent),
                    Container(height: 36, width: 1, color: AppColors.lightBorder),
                    _buildStatColumn('12', 'Resets tried', AppColors.lightAccent),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Navigation List Card
              EbbCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.lightAccentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_events_rounded, color: AppColors.lightAccent, size: 20),
                      ),
                      title: const Text('Goals and badges', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('4 of 5 resets this week'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/goals-badges'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.lightAccentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.lightAccent, size: 20),
                      ),
                      title: const Text('Journal', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('12 entries'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/journal'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.lightAccentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_rounded, color: AppColors.lightAccent, size: 20),
                      ),
                      title: const Text('Nudge settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Balanced, 3 a day'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/nudge-settings'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.lightAccentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.call_rounded, color: AppColors.lightAccent, size: 20),
                      ),
                      title: const Text('Support and helplines', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Reach a person any time'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Card
              EbbCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.lightPaper, shape: BoxShape.circle),
                        child: const Icon(Icons.nightlight_round, size: 20, color: AppColors.lightTextSecondary),
                      ),
                      title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _darkMode,
                      activeColor: AppColors.lightAccent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _darkMode = val),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.lightPaper, shape: BoxShape.circle),
                        child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.lightTextSecondary),
                      ),
                      title: const Text('Data and privacy', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Linked study data & context signals'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/health'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Log out button
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: AppColors.lightRose,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
