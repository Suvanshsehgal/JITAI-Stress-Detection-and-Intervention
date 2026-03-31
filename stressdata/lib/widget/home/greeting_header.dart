import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class GreetingHeader extends StatelessWidget {
  final String name;

  const GreetingHeader({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hi, $name',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
