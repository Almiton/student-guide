import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;

  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
              themeMode: widget.themeMode,
              onThemeChanged: widget.onThemeChanged,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Сплошной базовый слой, чтобы избежать черного фона под ним во время анимации
          Container(
            color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8FAFC),
          ),
          // Пульсирующий градиентный фоновый слой с мягким свечением
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0F0F1A),
                                  const Color(0xFF16162A),
                                  const Color(0xFF1E1E38),
                                ]
                              : [
                                  const Color(0xFFF8FAFC),
                                  const Color(0xFFF1F5F9),
                                  const Color(0xFFE2E8F0),
                                ],
                        ),
                      ),
                    ),
                    // Мягкое фоновое свечение (аккуратный круг)
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              blurRadius: 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      left: -150,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF06B6D4,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              blurRadius: 120,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Центральное содержимое (только логотип, с «дышащей» анимацией масштаба и прозрачности)
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                final introOpacity = _fadeAnimation.value;
                final introScale = _scaleAnimation.value;

                final pulseValue = _pulseAnimation.value;
                final currentPulseOpacity = 0.5 + (0.5 * pulseValue);
                final currentPulseScale = 0.95 + (0.1 * pulseValue);

                return Opacity(
                  opacity: introOpacity * currentPulseOpacity,
                  child: Transform.scale(
                    scale: introScale * currentPulseScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(34),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35 * currentPulseOpacity),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
