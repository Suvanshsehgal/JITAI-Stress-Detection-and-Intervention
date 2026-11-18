import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import 'providers/intervention_provider.dart';

class ToolboxScreen extends ConsumerStatefulWidget {
  const ToolboxScreen({super.key});

  @override
  ConsumerState<ToolboxScreen> createState() => _ToolboxScreenState();
}

class _ToolboxScreenState extends ConsumerState<ToolboxScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Breathing', 'Grounding', 'Move'];

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(interventionCatalogProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _selectedFilter == 'All'
        ? catalog
        : catalog.where((i) {
            return i.difficulty.toLowerCase() == _selectedFilter.toLowerCase();
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toolkit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const Text(
              'Techniques that fit how you feel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.lightTextPrimary),
            tooltip: 'Session History',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: isDark ? AppColors.darkBrand : AppColors.lightBrand,
                      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                      elevation: isSelected ? 2 : 0,
                      shadowColor: const Color(0x20352520),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pill,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 1.2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 2-Column Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.96,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final dotColor = Color(int.tryParse(item.icon) ?? 0xFFEE7A5C);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/intervention/${item.id}'),
                      borderRadius: AppRadius.cardRadius,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.2,
                          ),
                          boxShadow: isDark ? AppShadows.darkCardShadow : AppShadows.lightCardShadow,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: dotColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.2,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkPaper : AppColors.lightPaper,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.duration} · ${item.difficulty}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
