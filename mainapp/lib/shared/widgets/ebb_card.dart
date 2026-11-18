import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';

class EbbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;
  final BorderRadius? borderRadius;

  const EbbCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.cardRadius;

    final content = Container(
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: radius,
        border: border ?? Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: isDark ? AppShadows.darkCardShadow : AppShadows.lightCardShadow,
      ),
      padding: padding ?? const EdgeInsets.all(20.0),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: content,
    );
  }
}
