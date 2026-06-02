import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'package:package_info_plus/package_info_plus.dart';
import 'campuses_screen.dart';
import 'dormitories_screen.dart';
import 'activities_screen.dart';
import 'faq_screen.dart';
import 'scores_screen.dart';
import '../utils/app_utils.dart';

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

  // Стабильные ключи для экранов (ValueKey вместо PageStorageKey для сброса состояния)
  final Key _campusesKey = const ValueKey('campuses');
  final Key _dormitoriesKey = const ValueKey('dormitories');
  final Key _activitiesKey = const ValueKey('activities');
  final Key _faqKey = const ValueKey('faq');

  // Контроллер анимации и состояние для премиального переключения темы через плавное затухание (cross-fade)
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

  String _appVersion = '...';

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = '1.3.2'; // Дефолтное значение
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        final targetIndex = _pageController.page!.round();
        if (targetIndex != _currentIndex) {
          setState(() {
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

  void _showAboutAppDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AboutDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
        final opacity = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut));

        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: scale,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E1E38).withValues(alpha: 0.85),
                              const Color(0xFF16162A).withValues(alpha: 0.85),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.9),
                              const Color(0xFFF1F5F9).withValues(alpha: 0.9),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.1,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.1),
                                    width: 2,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Гид студента',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Версия $_appVersion',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Divider(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                                height: 1,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Разработчик:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      AppUtils.openContact(
                                        context,
                                        'https://github.com/Almiton',
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.terminal,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Daniil Khan',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      AppUtils.openContact(
                                        context,
                                        'https://github.com/Almiton/student-guide',
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.code,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Проект на GitHub',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF8B5CF6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Отлично',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

      // Делаем скриншот экрана с текущей (старой) темой
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      setState(() {
        _screenshot = image;
        _animating = true;
      });

      // Мгновенно переключаем тему приложения
      widget.onThemeChanged();

      // Запускаем анимацию исчезновения скриншота со старой темой
      _revealController.forward(from: 0.0);
    } catch (e) {
      // Запасной вариант на случай ошибок захвата скриншота
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
          // Заголовок всегда по центру; FittedBox масштабирует текст если он длинный
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.info_rounded,
              color: isDark
                  ? const Color(0xFFC084FC)
                  : const Color(0xFF8B5CF6),
              size: 22,
            ),
            onPressed: () => _showAboutAppDialog(context),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            reverseDuration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Одинаковый fade + лёгкий сдвиг снизу для всех вкладок
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: FittedBox(
              key: ValueKey<int>(_currentIndex),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                _titles[_currentIndex],
                maxLines: 1,
              ),
            ),
          ),
          actions: [
            ThemeToggleButton(isDark: isDark, onPressed: _handleThemeToggle),
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

    // Оборачиваем Scaffold в RepaintBoundary для возможности сделать скриншот
    content = RepaintBoundary(key: _boundaryKey, child: content);

    // Накладываем скриншот старой темы и плавно его скрываем
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
            painter: SunMoonPainter(progress: progress, color: iconColor),
          ),
        );
      },
    );
  }
}

class SunMoonPainter extends CustomPainter {
  final double progress;
  final Color color;

  SunMoonPainter({required this.progress, required this.color});

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

    // 1. Рисуем солнечные лучи.
    // 8 лучей, по часовой стрелке, начиная с верхней центральной точки (угол -pi / 2).
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
        final double angle =
            -3.141592653589793 / 2 + i * (3.141592653589793 / 4);
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

    // 2. Рисуем центральный круг с вырезом в форме полумесяца
    final double maskDx = R * (2.0 - 1.35 * progress);
    final double maskDy = -R * (2.0 - 1.75 * progress);
    final Offset maskCenter = Offset(center.dx + maskDx, center.dy + maskDy);

    final Path sunPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: R));
    final Path maskPath = Path()
      ..addOval(Rect.fromCircle(center: maskCenter, radius: R));

    final Path moonPath = Path.combine(
      PathOperation.difference,
      sunPath,
      maskPath,
    );

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
