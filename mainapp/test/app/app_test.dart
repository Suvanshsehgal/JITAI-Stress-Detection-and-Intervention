import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mainapp/app/app.dart';
import 'package:mainapp/app/theme/app_theme.dart';

void main() {
  testWidgets('EbbApp renders without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EbbApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('Themes can be constructed', () {
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;
    
    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
  });
}
