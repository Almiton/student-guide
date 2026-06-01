import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/splash_screen.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

void main() {
  runApp(const StudentGuideApp());
}

class StudentGuideApp extends StatefulWidget {
  const StudentGuideApp({super.key});

  @override
  State<StudentGuideApp> createState() => _StudentGuideAppState();
}

class _StudentGuideAppState extends State<StudentGuideApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      title: 'Гид студента',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ).copyWith(secondary: const Color(0xFF0891B2)),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          actionsIconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF7C3AED),
          unselectedItemColor: Color(0xFF64748B),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF475569)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.dark,
            ).copyWith(
              secondary: const Color(0xFF06B6D4),
              surface: const Color(0xFF16162A),
            ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E38),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF16162A),
          selectedItemColor: Color(0xFF8B5CF6),
          unselectedItemColor: Color(0xFF64748B),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
      ),
      home: SplashScreen(themeMode: _themeMode, onThemeChanged: _toggleTheme),
    );
  }
}
