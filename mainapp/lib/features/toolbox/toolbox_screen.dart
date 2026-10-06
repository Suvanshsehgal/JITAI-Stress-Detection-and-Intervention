import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/intervention.dart';
import 'providers/intervention_provider.dart';

class ToolboxScreen extends ConsumerStatefulWidget {
  const ToolboxScreen({super.key});

  @override
  ConsumerState<ToolboxScreen> createState() => _ToolboxScreenState();
}

class _ToolboxScreenState extends ConsumerState<ToolboxScreen> {
  InterventionCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(interventionCatalogProvider);
    final theme = Theme.of(context);

    final filtered = _selectedCategory == null
        ? catalog
        : catalog.where((i) => i.category == _selectedCategory).toList();

    // Group interventions by category for "All" view
    final grouped = <InterventionCategory, List<Intervention>>{};
    for (final intervention in filtered) {
      grouped.putIfAbsent(intervention.category, () => []).add(intervention);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Session History',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category filter chips carousel
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _selectedCategory == null,
                      label: const Text('All Tools'),
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                      },
                    ),
                  ),
                  ...InterventionCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: Icon(_categoryIcon(cat), size: 16),
                        selected: isSelected,
                        label: Text('${_categoryName(cat)} Tools'),
                        tooltip: 'Filter by ${_categoryName(cat)}',
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = val ? cat : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            // Interventions list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No exercises in this category yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final category = grouped.keys.elementAt(index);
                        final interventions = grouped[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _categoryIcon(category),
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _categoryName(category),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...interventions
                                .map((i) => _buildInterventionCard(context, theme, i)),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryName(InterventionCategory category) {
    switch (category) {
      case InterventionCategory.calmDown:
        return 'Calm Down';
      case InterventionCategory.reset:
        return 'Reset';
      case InterventionCategory.focus:
        return 'Focus';
      case InterventionCategory.sleep:
        return 'Sleep';
      case InterventionCategory.body:
        return 'Body';
      case InterventionCategory.reflect:
        return 'Reflect';
      case InterventionCategory.immediateHelp:
        return 'Immediate Help';
    }
  }

  IconData _categoryIcon(InterventionCategory category) {
    switch (category) {
      case InterventionCategory.calmDown:
        return Icons.air_rounded;
      case InterventionCategory.reset:
        return Icons.restart_alt_rounded;
      case InterventionCategory.focus:
        return Icons.center_focus_strong_rounded;
      case InterventionCategory.sleep:
        return Icons.nights_stay_rounded;
      case InterventionCategory.body:
        return Icons.accessibility_new_rounded;
      case InterventionCategory.reflect:
        return Icons.self_improvement_rounded;
      case InterventionCategory.immediateHelp:
        return Icons.support_rounded;
    }
  }

  Widget _buildInterventionCard(
      BuildContext context, ThemeData theme, Intervention intervention) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/intervention/${intervention.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(intervention.category),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            intervention.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            intervention.duration,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      intervention.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          intervention.difficulty,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
