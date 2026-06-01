import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'campuses_screen.dart';
import 'dormitories_screen.dart';
import 'activities_screen.dart';
import 'faq_screen.dart';
import 'scores_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  // Динамические ключи для сброса состояния экранов при переключении табов
  Key _campusesKey = UniqueKey();
  Key _dormitoriesKey = UniqueKey();
  Key _activitiesKey = UniqueKey();
  Key _faqKey = UniqueKey();

  // Animation controller and state for the premium cross-fade theme transition
  late final AnimationController _revealController;
  ui.Image? _screenshot;
  bool _animating = false;

  final GlobalKey _boundaryKey = GlobalKey();

  final List<String> _titles = const [
    'Корпуса и Кафедры',
    'Студенческие Общежития',
    'Проходные Баллы ЕГЭ',
    'Студенческая Жизнь',
    'Вопросы и Ответы',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        final targetIndex = _pageController.page!.round();
        if (targetIndex != _currentIndex) {
          setState(() {
            if (_currentIndex == 0 || targetIndex == 0) _campusesKey = UniqueKey();
            if (_currentIndex == 1 || targetIndex == 1) _dormitoriesKey = UniqueKey();
            if (_currentIndex == 3 || targetIndex == 3) _activitiesKey = UniqueKey();
            if (_currentIndex == 4 || targetIndex == 4) _faqKey = UniqueKey();
            _currentIndex = targetIndex;
          });
        }
      }
    });
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _screenshot?.dispose();
          _screenshot = null;
          _animating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _revealController.dispose();
    _screenshot?.dispose();
    super.dispose();
  }

  Future<void> _handleThemeToggle() async {
    if (_animating) return;

    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        widget.onThemeChanged();
        return;
      }

      // Capture the screenshot of the screen with the current (old) theme
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      setState(() {
        _screenshot = image;
        _animating = true;
      });

      // Switch the app theme instantly
      widget.onThemeChanged();

      // Animate the fade-out of the old theme screenshot
      _revealController.forward(from: 0.0);
    } catch (e) {
      // Fallback in case of capture errors
      widget.onThemeChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      CampusesScreen(key: _campusesKey),
      DormitoriesScreen(key: _dormitoriesKey),
      const ScoresScreen(), // Сохраняет состояние при переключениях
      ActivitiesScreen(key: _activitiesKey),
      FAQScreen(key: _faqKey),
    ];

    Widget content = GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Text(
              _titles[_currentIndex],
              key: ValueKey<int>(_currentIndex),
            ),
          ),
          actions: [
            ThemeToggleButton(
              isDark: isDark,
              onPressed: _handleThemeToggle,
            ),
          ],
        ),
        body: PageView(
          physics: const BouncingScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            // Индекс теперь обновляется плавно через listener в initState
          },
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Theme(
            data: theme.copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: const Color(0xFF8B5CF6),
              unselectedItemColor: const Color(0xFF64748B),
              selectedIconTheme: const IconThemeData(size: 28),
              unselectedIconTheme: const IconThemeData(size: 22),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              onTap: (index) {
                if (index != _currentIndex) {
                  setState(() {
                    if (_currentIndex == 0 || index == 0) _campusesKey = UniqueKey();
                    if (_currentIndex == 1 || index == 1) _dormitoriesKey = UniqueKey();
                    if (_currentIndex == 3 || index == 3) _activitiesKey = UniqueKey();
                    if (_currentIndex == 4 || index == 4) _faqKey = UniqueKey();
                    _currentIndex = index;
                  });
                }
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance),
                  activeIcon: Icon(Icons.account_balance),
                  label: 'Корпуса',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.hotel),
                  activeIcon: Icon(Icons.hotel),
                  label: 'Общежития',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard_outlined),
                  activeIcon: Icon(Icons.leaderboard),
                  label: 'Баллы ЕГЭ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.diversity_3),
                  activeIcon: Icon(Icons.diversity_3),
                  label: 'Активности',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.help_outline),
                  activeIcon: Icon(Icons.help),
                  label: 'FAQ',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap Scaffold in a RepaintBoundary to capture it
    content = RepaintBoundary(key: _boundaryKey, child: content);

    // Overlay screenshot of old theme and fade it out
    if (_screenshot != null) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _revealController,
                builder: (context, _) {
                  return Opacity(
                    opacity: (1.0 - _revealController.value).clamp(0.0, 1.0),
                    child: RawImage(image: _screenshot, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }
}

class ThemeToggleButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: widget.isDark ? 0.0 : 1.0,
    );
  }

  @override
  void didUpdateWidget(ThemeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      if (widget.isDark) {
        _controller.animateTo(0.0, curve: Curves.easeInOutCubic);
      } else {
        _controller.animateTo(1.0, curve: Curves.easeInOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final Color iconColor = Color.lerp(
          const Color(0xFF8B5CF6),
          const Color(0xFF64748B),
          progress,
        )!;

        return IconButton(
          onPressed: widget.onPressed,
          icon: CustomPaint(
            size: const Size(26, 26),
            painter: SunMoonPainter(
              progress: progress,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }
}

class SunMoonPainter extends CustomPainter {
  final double progress;
  final Color color;

  SunMoonPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxR = size.width / 2;
    final double R = maxR * (0.45 + 0.20 * progress);

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rayPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Draw sun rays.
    // 8 rays, clock-wise starting from top center (angle -pi / 2).
    for (int i = 0; i < 8; i++) {
      final double start = i * 0.125;
      final double end = (i + 1) * 0.125;
      double rayProgress = 0.0;

      if (progress <= start) {
        rayProgress = 1.0;
      } else if (progress >= end) {
        rayProgress = 0.0;
      } else {
        rayProgress = 1.0 - (progress - start) / 0.125;
      }

      if (rayProgress > 0.0) {
        final double angle = -3.141592653589793 / 2 + i * (3.141592653589793 / 4);
        final double startR = R + 2.5;
        final double maxRayLen = maxR - startR - 0.5;
        final double rayLen = maxRayLen * rayProgress;

        final Offset p1 = Offset(
          center.dx + startR * math.cos(angle),
          center.dy + startR * math.sin(angle),
        );
        final Offset p2 = Offset(
          center.dx + (startR + rayLen) * math.cos(angle),
          center.dy + (startR + rayLen) * math.sin(angle),
        );

        canvas.drawLine(p1, p2, rayPaint);
      }
    }

    // 2. Draw center circle with moon cut-out
    final double maskDx = R * (2.0 - 1.35 * progress);
    final double maskDy = -R * (2.0 - 1.75 * progress);
    final Offset maskCenter = Offset(center.dx + maskDx, center.dy + maskDy);

    final Path sunPath = Path()..addOval(Rect.fromCircle(center: center, radius: R));
    final Path maskPath = Path()..addOval(Rect.fromCircle(center: maskCenter, radius: R));

    final Path moonPath = Path.combine(PathOperation.difference, sunPath, maskPath);

    canvas.drawPath(moonPath, bodyPaint);

    // Добавляем скругление краев полумесяца с помощью stroke с округлыми стыками
    if (progress > 0.0) {
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * progress
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(moonPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SunMoonPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

