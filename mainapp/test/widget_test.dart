import 'package:flutter_test/flutter_test.dart';
import 'package:mainapp/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that our initial text is present.
    expect(find.text('JITAI Intervention App'), findsOneWidget);
  });
}
