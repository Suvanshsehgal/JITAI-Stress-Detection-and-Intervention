import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../shared/widgets/ebb_button.dart';
import '../../shared/widgets/ebb_card.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedMood = 'Okay';
  final Set<String> _selectedTags = {'Exams'};

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Great', 'color': Color(0xFF81C784), 'icon': Icons.sentiment_very_satisfied_rounded},
    {'label': 'Good', 'color': Color(0xFFFFD54F), 'icon': Icons.sentiment_satisfied_rounded},
    {'label': 'Okay', 'color': Color(0xFFD7CCC8), 'icon': Icons.sentiment_neutral_rounded},
    {'label': 'Low', 'color': Color(0xFFFFB74D), 'icon': Icons.sentiment_dissatisfied_rounded},
    {'label': 'Stressed', 'color': Color(0xFFBA68C8), 'icon': Icons.sentiment_very_dissatisfied_rounded},
  ];

  final List<String> _tags = ['Exams', 'Sleep', 'Family', 'Friends', 'Work', 'Health'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Journal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling right now?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Mood Face Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _moods.map((item) {
                  final label = item['label'] as String;
                  final color = item['color'] as Color;
                  final icon = item['icon'] as IconData;
                  final isSelected = _selectedMood == label;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = label),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withAlpha(isSelected ? 255 : 90),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.lightBrand : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(icon, color: isSelected ? Colors.white : AppColors.lightTextPrimary, size: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Text writing area
              EbbCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      maxLength: 280,
                      decoration: const InputDecoration(
                        hintText: 'What is on your mind? Write a few words.',
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.lightAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tag Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.lightBrand,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppColors.lightBorder,
                      width: 1.2,
                    ),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save Entry Button
              SizedBox(
                width: double.infinity,
                child: EbbButton(
                  label: 'Save entry',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Journal entry recorded.')),
                    );
                    context.pop();
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Recent entries list
              Text(
                'Recent entries',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),

              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB74D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sentiment_dissatisfied_rounded, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('Today, 14:20', style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightPaper,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Score 38', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Exam tomorrow. Did a breathing reset and felt lighter.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              EbbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sentiment_satisfied_rounded, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('Yesterday', style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightPaper,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Score 29', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Long walk after class helped me focus.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
