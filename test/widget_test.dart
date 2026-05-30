import 'package:flutter_test/flutter_test.dart';
import 'package:student_guide/main.dart';

void main() {
  testWidgets('Student Guide App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudentGuideApp());

    // Move virtual time forward to trigger Timer in SplashScreen (600ms)
    // and let the PageRoute transition finish (300ms).
    await tester.pump(const Duration(milliseconds: 1000));
    // Pump another frame to build the HomeScreen widgets
    await tester.pump();

    // Verify that the App Bar starts with the first tab title.
    expect(find.text('Корпуса и Кафедры'), findsOneWidget);
  });
}
