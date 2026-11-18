import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../toolbox/providers/intervention_provider.dart';
import '../../../shared/widgets/ebb_button.dart';

class InterventionDetailScreen extends ConsumerWidget {
  final String interventionId;

  const InterventionDetailScreen({super.key, required this.interventionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(interventionCatalogProvider);
    final intervention = catalog.cast<dynamic>().firstWhere(
          (i) => i.id == interventionId,
          orElse: () => null,
        );

    if (intervention == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Intervention not found.')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(intervention.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightAccentSoft,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        '${intervention.duration} · ${intervention.difficulty}',
                        style: const TextStyle(
                          color: AppColors.lightAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Purpose',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intervention.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...intervention.instructions.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.lightBrand,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                e.value,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: EbbButton(
                  label: 'Start Session',
                  onPressed: () {
                    context.replace('/intervention/$interventionId/run');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
