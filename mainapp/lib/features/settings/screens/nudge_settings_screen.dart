import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../shared/widgets/ebb_card.dart';
import '../../jitai/widgets/smart_nudge_sheet.dart';

class NudgeSettingsScreen extends StatefulWidget {
  const NudgeSettingsScreen({super.key});

  @override
  State<NudgeSettingsScreen> createState() => _NudgeSettingsScreenState();
}

class _NudgeSettingsScreenState extends State<NudgeSettingsScreen> {
  bool _smartNudgesEnabled = true;
  String _sensitivity = 'Balanced';
  int _maxNudges = 3;

  bool _breathingEnabled = true;
  bool _movementEnabled = true;
  bool _groundingEnabled = true;
  bool _calmSoundsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nudge settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            // Smart nudges switch card
            EbbCard(
              child: SwitchListTile(
                title: const Text(
                  'Smart nudges',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text('Suggest a reset when your stress rises'),
                value: _smartNudgesEnabled,
                activeColor: AppColors.lightAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _smartNudgesEnabled = val),
              ),
            ),
            const SizedBox(height: 20),

            // Sensitivity Segmented Control
            Text(
              'Sensitivity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                children: ['Gentle', 'Balanced', 'Proactive'].map((level) {
                  final isSelected = _sensitivity == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sensitivity = level),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.lightBrand : Colors.transparent,
                          borderRadius: AppRadius.pill,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          level,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Balanced nudges you when your score stays above your usual for 20 minutes.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 24),

            // Quiet hours & Max nudges
            EbbCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.lightPaper,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.nightlight_round, size: 18, color: AppColors.lightAccent),
                    ),
                    title: const Text('Quiet hours', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('10:00 PM to 7:00 AM'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.lightPaper,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded, size: 18, color: AppColors.lightAccent),
                    ),
                    title: const Text('Max nudges a day', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: _maxNudges > 1 ? () => setState(() => _maxNudges--) : null,
                        ),
                        Text('$_maxNudges', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          onPressed: _maxNudges < 10 ? () => setState(() => _maxNudges++) : null,
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nudge types
            Text(
              'Nudge types',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            EbbCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.favorite_outline_rounded, color: AppColors.lightAccent),
                    title: const Text('Breathing reset'),
                    value: _breathingEnabled,
                    activeColor: AppColors.lightAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _breathingEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.directions_walk_rounded, color: AppColors.lightAccent),
                    title: const Text('Movement break'),
                    value: _movementEnabled,
                    activeColor: AppColors.lightAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _movementEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.grid_view_rounded, color: AppColors.lightAccent),
                    title: const Text('Grounding'),
                    value: _groundingEnabled,
                    activeColor: AppColors.lightAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _groundingEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.music_note_rounded, color: AppColors.lightAccent),
                    title: const Text('Calming sounds'),
                    value: _calmSoundsEnabled,
                    activeColor: AppColors.lightAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _calmSoundsEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview a nudge button
            Center(
              child: TextButton(
                onPressed: () => SmartNudgeSheet.show(context),
                child: const Text(
                  'Preview a nudge',
                  style: TextStyle(
                    color: AppColors.lightAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
