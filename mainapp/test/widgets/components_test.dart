import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/shared/widgets/ebb_button.dart';
import 'package:mainapp/shared/widgets/ebb_card.dart';

void main() {
  testWidgets('EbbButton renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EbbButton(label: 'Test Button', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('EbbCard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EbbCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}
