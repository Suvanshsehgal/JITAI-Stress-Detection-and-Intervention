import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/session_history_provider.dart';
import 'providers/intervention_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryProvider);
    final catalog = ref.watch(interventionCatalogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                'No completed sessions yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final session = history[index];
                final intervention = catalog.cast<dynamic>().firstWhere(
                      (i) => i.id == session.interventionId,
                      orElse: () => null,
                    );

                return ListTile(
                  title: Text(intervention?.title ?? 'Unknown Intervention'),
                  subtitle: Text(_formatDate(session.startedAt)),
                  trailing: session.postMood != null 
                      ? Text(session.postMood!) 
                      : null,
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
