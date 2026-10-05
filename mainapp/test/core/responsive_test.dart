import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/core/responsive/responsive_layout.dart';

void main() {
  testWidgets('ResponsiveLayout shows mobile on small screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveLayout(
            mobile: Text('MobileView'),
            tablet: Text('TabletView'),
            desktop: Text('DesktopView'),
          ),
        ),
      ),
    );

    expect(find.text('MobileView'), findsOneWidget);
    
    // Reset
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('ResponsiveLayout shows desktop on large screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveLayout(
            mobile: Text('MobileView'),
            tablet: Text('TabletView'),
            desktop: Text('DesktopView'),
          ),
        ),
      ),
    );

    expect(find.text('DesktopView'), findsOneWidget);
    
    // Reset
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
