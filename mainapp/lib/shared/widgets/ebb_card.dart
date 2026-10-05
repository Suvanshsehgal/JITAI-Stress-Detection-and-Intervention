import 'package:flutter/material.dart';

class EbbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const EbbCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
