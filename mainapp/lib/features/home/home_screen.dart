import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ebb_button.dart';
import '../../shared/widgets/ebb_card.dart';
import '../../core/responsive/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: ResponsiveLayout(
        mobile: _buildContent(context, 'Mobile Layout'),
        tablet: _buildContent(context, 'Tablet Layout'),
        desktop: _buildContent(context, 'Desktop Layout'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String layout) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(layout, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          EbbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Navigation', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EbbButton(
                      label: 'Go to Buddy',
                      onPressed: () => context.push('/buddy'),
                    ),
                    EbbButton(
                      label: 'Go to Toolbox',
                      isSecondary: true,
                      onPressed: () => context.push('/toolbox'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
