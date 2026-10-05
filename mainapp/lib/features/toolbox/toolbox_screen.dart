import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/intervention_provider.dart';
import 'models/intervention.dart';

class ToolboxScreen extends ConsumerWidget {
  const ToolboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(interventionCatalogProvider);
    final theme = Theme.of(context);

    // Group interventions by category
    final grouped = <InterventionCategory, List<Intervention>>{};
    for (var intervention in catalog) {
      grouped.putIfAbsent(intervention.category, () => []).add(intervention);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push('/history'),
          )
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final category = grouped.keys.elementAt(index);
            final interventions = grouped[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _categoryName(category),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...interventions.map((i) => _buildInterventionCard(context, theme, i)),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  String _categoryName(InterventionCategory category) {
    switch (category) {
      case InterventionCategory.calmDown: return 'Calm Down';
      case InterventionCategory.reset: return 'Reset';
      case InterventionCategory.focus: return 'Focus';
      case InterventionCategory.sleep: return 'Sleep';
      case InterventionCategory.body: return 'Body';
      case InterventionCategory.reflect: return 'Reflect';
      case InterventionCategory.immediateHelp: return 'Immediate Help';
    }
  }

  Widget _buildInterventionCard(BuildContext context, ThemeData theme, Intervention intervention) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/intervention/${intervention.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.self_improvement), // Hardcoded icon for now
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intervention.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${intervention.duration} • ${intervention.difficulty}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
