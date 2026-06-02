import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  /// Копирует указанный текст в буфер обмена и показывает Snackbar с уведомлением.
  static void copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label скопирован в буфер обмена'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Открывает маршрут на картах по адресу.
  static Future<void> openMapRoute(BuildContext context, String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    Uri url;
    if (kIsWeb) {
      url = Uri.parse('https://maps.google.com/?q=$encodedAddress');
    } else if (Platform.isAndroid) {
      url = Uri.parse('geo:0,0?q=$encodedAddress');
    } else if (Platform.isIOS) {
      url = Uri.parse('maps://?q=$encodedAddress');
    } else {
      url = Uri.parse('https://maps.google.com/?q=$encodedAddress');
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        final webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось открыть карты'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Открывает системную звонилку для указанного номера телефона.
  static Future<void> openDialer(BuildContext context, String phone) async {
    final String sanitizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$sanitizedPhone');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось открыть телефон'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось открыть телефон'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Универсальный метод для открытия контакта (телефона или веб-ссылки).
  static Future<void> openContact(BuildContext context, String contact) async {
    final isPhone = RegExp(r'^\+?[0-9\s()\-]{7,}$').hasMatch(contact);
    if (isPhone) {
      await openDialer(context, contact);
    } else {
      String urlString = contact;
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      final Uri url = Uri.parse(urlString);
      try {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось открыть ссылку'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось открыть ссылку'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Возвращает цвет, соответствующий указанному факультету.
  static Color getFacultyColor(String faculty) {
    switch (faculty) {
      case 'ФКН':
        return const Color(0xFF8B5CF6); // Фиолетовый
      case 'ПММ':
        return const Color(0xFF06B6D4); // Голубой
      case 'Экономический':
        return const Color(0xFF10B981); // Изумрудный
      case 'Юридический':
        return const Color(0xFFF59E0B); // Янтарный
      case 'Журналистики':
        return const Color(0xFFF43F5E); // Розовый
      case 'РГФ':
        return const Color(0xFF3B82F6); // Синий
      case 'Исторический':
        return const Color(0xFFD97706); // Оранжево-коричневый
      case 'Физический':
        return const Color(0xFFD946EF); // Фуксия / Пурпурный
      case 'Химический':
        return const Color(0xFF14B8A6); // Бирюзовый
      case 'Математический':
        return const Color(0xFF6366F1); // Индиго
      case 'Геологический':
        return const Color(0xFF78350F); // Коричневый
      case 'Медико-биологический':
        return const Color(0xFF059669); // Изумрудно-зеленый
      case 'Фармацевтический':
        return const Color(0xFF0D9488); // Бирюзово-зеленый
      case 'Филологический':
        return const Color(0xFFEC4899); // Розовый
      case 'Философии и психологии':
        return const Color(0xFF8B5CF6); // Пурпурный
      case 'Географии и туризма':
        return const Color(0xFF047857); // Темно-зеленый
      case 'ФМО':
        return const Color(0xFF0284C7); // Небесно-голубой
      case 'Передовая инженерная школа «Российская электроника, инфокоммуникации и радиосвязь»':
        return const Color(0xFF0F766E); // Глубокий бирюзовый
      default:
        return const Color(0xFF64748B); // Грифельный / Серый
    }
  }

  /// Возвращает правильное склонение слова "место" в зависимости от числа.
  static String getPluralSpots(int count) {
    final int mod10 = count % 10;
    final int mod100 = count % 100;
    
    if (mod100 >= 11 && mod100 <= 14) {
      return '$count мест';
    }
    if (mod10 == 1) {
      return '$count место';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count места';
    }
    return '$count мест';
  }

  /// Сопоставляет факультет по полному названию или аббревиатуре.
  static bool matchFaculty(String facultyName, String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return false;
    
    final cleanFaculty = facultyName.toLowerCase();
    if (cleanFaculty.contains(cleanQuery)) return true;

    // База сокращений
    final abbreviations = {
      'фкн': ['факультет компьютерных наук', 'компьютерных наук', 'фкн'],
      'пмм': ['прикладной математики', 'пмм', 'прикладной математики, информатики и механики'],
      'ргф': ['романс-германской', 'романо-германской', 'ргф', 'романс-германской филологии', 'романо-германской филологии'],
      'фмо': ['международных отношений', 'фмо'],
      'ггит': ['географии', 'географии и туризма', 'ггит', 'географии, геоэкологии и туризма'],
      'физфак': ['физический', 'физфак'],
      'химфак': ['химический', 'химфак'],
      'истфак': ['исторический', 'истфак'],
      'юрфак': ['юридический', 'юрфак'],
      'журфак': ['журналистики', 'журфак'],
      'филфак': ['филологический', 'филфак'],
      'матфак': ['математический', 'матфак'],
      'биофак': ['медико-биологический', 'биофак'],
    };

    for (final entry in abbreviations.entries) {
      if (cleanQuery == entry.key) {
        for (final val in entry.value) {
          if (cleanFaculty.contains(val)) return true;
        }
      }
    }
    return false;
  }

  /// Сопоставляет кафедру по названию или аббревиатуре.
  static bool matchDepartment(String departmentName, String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return false;

    final cleanDept = departmentName.toLowerCase();
    if (cleanDept.contains(cleanQuery)) return true;

    // База сокращений кафедр
    final deptAbbr = {
      'сау': ['системного анализа и управления', 'сау'],
      'пит': ['программирования и информационных технологий', 'пит'],
      'поаис': ['программного обеспечения и администрирования информационных систем', 'поаис'],
      'ист': ['информационных систем и технологий', 'ист'],
      'вм': ['вычислительной математики', 'вм'],
    };

    for (final entry in deptAbbr.entries) {
      if (cleanQuery == entry.key) {
        for (final val in entry.value) {
          if (cleanDept.contains(val)) return true;
        }
      }
    }
    return false;
  }
}

class InteractiveFeedback extends StatefulWidget {
  final Widget child;
  final double scaleFactor;
  final BorderRadius? borderRadius;
  final Color? activeBorderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const InteractiveFeedback({
    super.key,
    required this.child,
    this.scaleFactor = 0.97,
    this.borderRadius,
    this.activeBorderColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<InteractiveFeedback> createState() => _InteractiveFeedbackState();
}

class _InteractiveFeedbackState extends State<InteractiveFeedback> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRad = widget.borderRadius ?? BorderRadius.circular(16);
    final activeColor = widget.activeBorderColor ?? theme.colorScheme.primary;

    return Listener(
      onPointerDown: (event) {
        setState(() {
          _isPressed = true;
        });
      },
      onPointerUp: (event) {
        setState(() {
          _isPressed = false;
        });
      },
      onPointerCancel: (event) {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: borderRad,
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: borderRad,
                      border: Border.all(
                        color: _isPressed
                            ? activeColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
