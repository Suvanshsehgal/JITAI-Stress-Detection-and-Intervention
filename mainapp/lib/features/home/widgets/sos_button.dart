import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SosButtonWidget extends StatelessWidget {
  const SosButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          context.push('/sos');
        },
        icon: Icon(Icons.shield_outlined, color: theme.colorScheme.error),
        label: const Text('SOS Access'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withAlpha(128)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
