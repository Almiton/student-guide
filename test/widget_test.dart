import 'package:flutter_test/flutter_test.dart';
import 'package:student_guide/main.dart';

void main() {
  testWidgets('Student Guide App smoke test', (WidgetTester tester) async {
    // Строим наше приложение и триггерим кадр.
    await tester.pumpWidget(const StudentGuideApp());

    // Перематываем виртуальное время вперед для срабатывания таймера в SplashScreen (600 мс)
    // и завершения анимации перехода PageRoute (300 мс).
    await tester.pump(const Duration(milliseconds: 1000));
    // Перерисовываем кадр для построения виджетов HomeScreen
    await tester.pump();

    // Проверяем, что App Bar открывается с заголовком первой вкладки.
    expect(find.text('Корпуса и Кафедры'), findsOneWidget);
  });
}
