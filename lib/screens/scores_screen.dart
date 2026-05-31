import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';
import 'comparison_screen.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen>
    with AutomaticKeepAliveClientMixin {
  late final Map<String, int> _minScores;
  String _searchQuery = '';
  String _selectedFaculty = 'Все';
  String? _highlightedFaculty;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _facultyScrollController = ScrollController();
  final Map<String, GlobalKey> _facultyKeys = {};

  void _scrollToFaculty(String faculty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final context = _facultyKeys[faculty]?.currentContext;
        if (context != null && context.mounted) {
          // ignore: use_build_context_synchronously
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: 0.0,
          );
        }
      });
    });
  }

  void _triggerFacultyFlash(String faculty) {
    if (faculty == 'Все') return;
    setState(() {
      _highlightedFaculty = faculty;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _highlightedFaculty == faculty) {
        setState(() {
          _highlightedFaculty = null;
        });
      }
    });
  }

  bool _showCalculator = false;
  final Map<String, int> _userScores = {};
  final Set<String> _selectedSubjects = {};
  final List<AdmissionScore> _compareList = [];
  String _sortBy =
      'alphabet'; // 'alphabet', 'scoreAsc', 'scoreDesc', 'priceAsc', 'priceDesc'

  int _extraAchievementsScore = 0;
  late final TextEditingController _achievementsController;

  List<String> get _faculties {
    final list = mockAdmissionScores.map((s) => s.facultyName).toSet().toList();
    list.sort((a, b) {
      final aCount = mockAdmissionScores
          .where((s) => s.facultyName == a)
          .length;
      final bCount = mockAdmissionScores
          .where((s) => s.facultyName == b)
          .length;
      final cmp = bCount.compareTo(aCount);
      if (cmp != 0) return cmp;
      return a.compareTo(b);
    });
    return ['Все', ...list];
  }

  late final Map<String, TextEditingController> _scoreControllers;

  @override
  void initState() {
    super.initState();
    _minScores = {};
    _scoreControllers = {};
    _achievementsController = TextEditingController(text: '0');

    final defaultMinScores = {
      'Математика (профиль)': 39,
      'Русский язык': 40,
      'Информатика': 44,
      'Физика': 39,
      'Обществознание': 45,
      'История': 35,
      'Иностранный язык': 30,
      'Биология': 39,
      'Химия': 39,
      'Литература': 40,
      'География': 40,
      'Внутренний экзамен(ы)': 40,
    };

    final subjects = <String>{};
    for (final score in mockAdmissionScores) {
      for (final subj in score.subjects) {
        if (subj.contains('/')) {
          for (final opt in subj.split('/')) {
            subjects.add(opt.trim());
          }
        } else {
          subjects.add(subj.trim());
        }
      }
    }

    final Map<String, int> subjectCounts = {};
    for (final score in mockAdmissionScores) {
      for (final subj in score.subjects) {
        if (subj.contains('/')) {
          for (final opt in subj.split('/')) {
            final cleanOpt = opt.trim();
            subjectCounts[cleanOpt] = (subjectCounts[cleanOpt] ?? 0) + 1;
          }
        } else {
          final cleanSubj = subj.trim();
          subjectCounts[cleanSubj] = (subjectCounts[cleanSubj] ?? 0) + 1;
        }
      }
    }

    final sortedSubjects = subjectCounts.keys.toList()
      ..sort((a, b) => subjectCounts[b]!.compareTo(subjectCounts[a]!));

    sortedSubjects.remove('Русский язык');
    sortedSubjects.remove('Математика (профиль)');

    sortedSubjects.insert(0, 'Русский язык');
    if (subjectCounts.containsKey('Математика (профиль)')) {
      sortedSubjects.insert(1, 'Математика (профиль)');
    }

    for (final subj in sortedSubjects) {
      _minScores[subj] = defaultMinScores[subj] ?? 40;
      _scoreControllers[subj] = TextEditingController();
    }

    // Инициализируем Русский язык как всегда выбранный
    if (sortedSubjects.contains('Русский язык')) {
      _selectedSubjects.add('Русский язык');
      final minVal = _minScores['Русский язык'] ?? 40;
      _userScores['Русский язык'] = minVal;
      _scoreControllers['Русский язык']?.text = minVal.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _facultyScrollController.dispose();
    _achievementsController.dispose();
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _getSpecCountForFaculty(String faculty) {
    return mockAdmissionScores.where((score) {
      final matchesSearch =
          score.directionName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          AppUtils.matchFaculty(score.facultyName, _searchQuery);

      final matchesFaculty = faculty == 'Все' || score.facultyName == faculty;

      bool matchesSubjects = true;
      for (final selectedSubj in _selectedSubjects) {
        bool specContainsSelected = false;
        for (final specSubj in score.subjects) {
          if (specSubj.contains('/')) {
            final options = specSubj.split('/');
            for (final opt in options) {
              if (opt.trim().toLowerCase() ==
                  selectedSubj.trim().toLowerCase()) {
                specContainsSelected = true;
                break;
              }
            }
          } else {
            if (specSubj.trim().toLowerCase() ==
                selectedSubj.trim().toLowerCase()) {
              specContainsSelected = true;
            }
          }
          if (specContainsSelected) break;
        }
        if (!specContainsSelected) {
          matchesSubjects = false;
          break;
        }
      }

      bool matchesScores = true;
      if (_userScores.isNotEmpty) {
        final userTotal = _calculateUserTotalForDirection(score);
        if (userTotal != null) {
          final target = score.passingScores[2025] ?? 0;
          if (target > 0 && userTotal < target) {
            matchesScores = false;
          }
        }
      }

      return matchesSearch &&
          matchesFaculty &&
          matchesSubjects &&
          matchesScores;
    }).length;
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  int? _calculateUserTotalForDirection(AdmissionScore score) {
    if (_userScores.isEmpty) return null;

    int total = 0;
    for (final subject in score.subjects) {
      if (subject.contains('/')) {
        final options = subject.split('/');
        int maxOptionScore = 0;
        bool hasAnyOption = false;
        for (final opt in options) {
          final cleanOpt = opt.trim();
          final userScore = _getUserScoreForSubject(cleanOpt);
          if (userScore != null) {
            hasAnyOption = true;
            if (userScore > maxOptionScore) {
              maxOptionScore = userScore;
            }
          }
        }
        if (!hasAnyOption) return null;
        total += maxOptionScore;
      } else {
        final userScore = _getUserScoreForSubject(subject);
        if (userScore == null) return null;
        total += userScore;
      }
    }
    return total + _extraAchievementsScore;
  }

  int? _getUserScoreForSubject(String subjectName) {
    final cleanName = subjectName.trim().toLowerCase();
    for (final entry in _userScores.entries) {
      final key = entry.key.trim().toLowerCase();
      if (key.contains(cleanName) || cleanName.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  int _parsePrice(String? priceString) {
    if (priceString == null) return 0;
    final clean = priceString.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Widget _buildSubjectRow(String subject, ThemeData theme) {
    final int minScore = _minScores[subject] ?? 40;
    final int currentVal = _userScores[subject] ?? minScore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    thumbColor: theme.colorScheme.primary,
                    overlayColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: currentVal.toDouble().clamp(
                      minScore.toDouble(),
                      100.0,
                    ),
                    min: minScore.toDouble(),
                    max: 100,
                    divisions: 100 - minScore,
                    label: currentVal.toString(),
                    onChanged: (value) {
                      setState(() {
                        final int score = value.round();
                        _userScores[subject] = score;
                        _scoreControllers[subject]?.text = score.toString();
                      });
                    },
                    onChangeEnd: (value) {
                      _scrollToTop();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: TextField(
                  controller: _scoreControllers[subject],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: minScore.toString(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      final score = int.tryParse(value);
                      if (score != null) {
                        if (score >= minScore) {
                          final clampedScore = score.clamp(0, 100);
                          _userScores[subject] = clampedScore;
                          if (score > 100) {
                            _scoreControllers[subject]?.text = '100';
                          }
                        } else {
                          if (value.length >= 2) {
                            _userScores[subject] = minScore;
                            _scoreControllers[subject]?.text = minScore
                                .toString();
                          } else {
                            _userScores[subject] = minScore;
                          }
                        }
                      } else {
                        _userScores[subject] = minScore;
                      }
                    });
                    _scrollToTop();
                  },
                  onEditingComplete: () {
                    setState(() {
                      final val = _scoreControllers[subject]?.text ?? '';
                      final score = int.tryParse(val);
                      if (score == null || score < minScore) {
                        _scoreControllers[subject]?.text = minScore.toString();
                        _userScores[subject] = minScore;
                      } else if (score > 100) {
                        _scoreControllers[subject]?.text = '100';
                        _userScores[subject] = 100;
                      }
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Индивидуальные достижения',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.secondary,
                    inactiveTrackColor: theme.colorScheme.secondary.withValues(
                      alpha: 0.2,
                    ),
                    thumbColor: theme.colorScheme.secondary,
                    overlayColor: theme.colorScheme.secondary.withValues(
                      alpha: 0.12,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _extraAchievementsScore.toDouble(),
                    min: 0.0,
                    max: 10.0,
                    divisions: 10,
                    label: _extraAchievementsScore.toString(),
                    onChanged: (value) {
                      setState(() {
                        _extraAchievementsScore = value.round();
                        _achievementsController.text = _extraAchievementsScore.toString();
                      });
                    },
                    onChangeEnd: (value) {
                      _scrollToTop();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: TextField(
                  controller: _achievementsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      final score = int.tryParse(value);
                      if (score != null) {
                        _extraAchievementsScore = score.clamp(0, 10);
                        if (score > 10) {
                          _achievementsController.text = '10';
                        }
                      } else {
                        _extraAchievementsScore = 0;
                      }
                    });
                    _scrollToTop();
                  },
                  onEditingComplete: () {
                    setState(() {
                      final val = _achievementsController.text;
                      final score = int.tryParse(val);
                      if (score == null) {
                        _achievementsController.text = '0';
                        _extraAchievementsScore = 0;
                      } else if (score > 10) {
                        _achievementsController.text = '10';
                        _extraAchievementsScore = 10;
                      }
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required BuildContext context,
    required String value,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _sortBy == value;
    final activeColor = theme.colorScheme.primary;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? activeColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 12),
            Icon(Icons.check, color: activeColor, size: 18),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final filteredScores = mockAdmissionScores.where((score) {
      final matchesSearch =
          score.directionName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          AppUtils.matchFaculty(score.facultyName, _searchQuery);
      final matchesFaculty =
          _selectedFaculty == 'Все' || score.facultyName == _selectedFaculty;

      bool matchesSubjects = true;
      for (final selectedSubj in _selectedSubjects) {
        bool specContainsSelected = false;
        for (final specSubj in score.subjects) {
          if (specSubj.contains('/')) {
            final options = specSubj.split('/');
            for (final opt in options) {
              if (opt.trim().toLowerCase() ==
                  selectedSubj.trim().toLowerCase()) {
                specContainsSelected = true;
                break;
              }
            }
          } else {
            if (specSubj.trim().toLowerCase() ==
                selectedSubj.trim().toLowerCase()) {
              specContainsSelected = true;
            }
          }
          if (specContainsSelected) break;
        }
        if (!specContainsSelected) {
          matchesSubjects = false;
          break;
        }
      }

      // 2. Фильтр по баллам
      bool matchesScores = true;
      if (_userScores.isNotEmpty) {
        final userTotal = _calculateUserTotalForDirection(score);
        if (userTotal != null) {
          final target = score.passingScores[2025] ?? 0;
          if (target > 0 && userTotal < target) {
            matchesScores = false;
          }
        }
      }

      return matchesSearch &&
          matchesFaculty &&
          matchesSubjects &&
          matchesScores;
    }).toList();

    // Apply sorting logic
    if (_sortBy == 'alphabet') {
      filteredScores.sort((a, b) => a.directionName.compareTo(b.directionName));
    } else if (_sortBy == 'scoreAsc') {
      filteredScores.sort((a, b) {
        final aScore = a.passingScores[2025] ?? 0;
        final bScore = b.passingScores[2025] ?? 0;
        return aScore.compareTo(bScore);
      });
    } else if (_sortBy == 'scoreDesc') {
      filteredScores.sort((a, b) {
        final aScore = a.passingScores[2025] ?? 0;
        final bScore = b.passingScores[2025] ?? 0;
        return bScore.compareTo(aScore);
      });
    } else if (_sortBy == 'priceAsc') {
      filteredScores.sort((a, b) {
        final aPrice = _parsePrice(a.price);
        final bPrice = _parsePrice(b.price);
        return aPrice.compareTo(bPrice);
      });
    } else if (_sortBy == 'priceDesc') {
      filteredScores.sort((a, b) {
        final aPrice = _parsePrice(a.price);
        final bPrice = _parsePrice(b.price);
        return bPrice.compareTo(aPrice);
      });
    }

    return Stack(
      children: [
        Column(
          children: [
            // Search Bar, Calculator Toggle & Sorting Popup Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Поиск направления или кода...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Calculator Toggle Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _showCalculator
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      foregroundColor: _showCalculator
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.calculate_outlined),
                    onPressed: () {
                      setState(() {
                        _showCalculator = !_showCalculator;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Sorting Menu
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.sort, color: theme.colorScheme.primary),
                      tooltip: 'Сортировка',
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                          width: 1,
                        ),
                      ),
                      color: theme.colorScheme.surface,
                      elevation: 6,
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                        _scrollToTop();
                      },
                      itemBuilder: (context) => [
                        _buildPopupMenuItem(
                          context: context,
                          value: 'alphabet',
                          title: 'По умолчанию',
                          icon: Icons.sort_by_alpha,
                        ),
                        const PopupMenuDivider(height: 1),
                        _buildPopupMenuItem(
                          context: context,
                          value: 'scoreAsc',
                          title: 'Баллы: по возрастанию',
                          icon: Icons.trending_up,
                        ),
                        _buildPopupMenuItem(
                          context: context,
                          value: 'scoreDesc',
                          title: 'Баллы: по убыванию',
                          icon: Icons.trending_down,
                        ),
                        const PopupMenuDivider(height: 1),
                        _buildPopupMenuItem(
                          context: context,
                          value: 'priceAsc',
                          title: 'Цена: по возрастанию',
                          icon: Icons.arrow_downward,
                        ),
                        _buildPopupMenuItem(
                          context: context,
                          value: 'priceDesc',
                          title: 'Цена: по убыванию',
                          icon: Icons.arrow_upward,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Collapsible Calculator Panel with Sliders
            if (_showCalculator)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _showCalculator = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Калькулятор баллов ЕГЭ',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 320,
                          child: ListView(
                            children: [
                              Text(
                                'Предметы для расчета шансов поступления:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _scoreControllers.keys.map((subject) {
                                  final isSelected = _selectedSubjects.contains(
                                    subject,
                                  );
                                  return InteractiveFeedback(
                                    borderRadius: BorderRadius.circular(8),
                                    activeBorderColor:
                                        theme.colorScheme.primary,
                                    child: FilterChip(
                                      label: Text(
                                        subject,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (subject == 'Русский язык') {
                                          return; // Русский язык нельзя убрать
                                        }
                                        setState(() {
                                          if (selected) {
                                            _selectedSubjects.add(subject);
                                            final minVal =
                                                _minScores[subject] ?? 40;
                                            _userScores[subject] = minVal;
                                            _scoreControllers[subject]?.text =
                                                minVal.toString();
                                          } else {
                                            _selectedSubjects.remove(subject);
                                            _userScores.remove(subject);
                                            _scoreControllers[subject]?.clear();
                                          }
                                        });
                                        _scrollToTop();
                                      },
                                      selectedColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      checkmarkColor: theme.colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.12),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              if (_selectedSubjects.length < 3)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Выберите как минимум 3 предмета ЕГЭ, чтобы указать баллы (${_selectedSubjects.length}/3)',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Укажите ваши баллы по предметам:',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._scoreControllers.keys
                                        .where(
                                          (s) => _selectedSubjects.contains(s),
                                        )
                                        .map(
                                          (subject) =>
                                              _buildSubjectRow(subject, theme),
                                        ),
                                    const Divider(height: 24),
                                    _buildAchievementsRow(theme),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _userScores.clear();
                                  _selectedSubjects.clear();
                                  for (final controller
                                      in _scoreControllers.values) {
                                    controller.clear();
                                  }
                                  _extraAchievementsScore = 0;
                                  _achievementsController.text = '0';
                                });
                              },
                              child: const Text('Сбросить баллы'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Faculty Selector
            SingleChildScrollView(
              controller: _facultyScrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ..._faculties
                      .where((faculty) {
                        if (faculty == 'Все') return true;
                        if (_selectedFaculty == faculty) return true;
                        return _getSpecCountForFaculty(faculty) > 0;
                      })
                      .map((faculty) {
                        final isSelected = _selectedFaculty == faculty;
                        final facColor = AppUtils.getFacultyColor(faculty);
                        final key = _facultyKeys.putIfAbsent(faculty, () => GlobalKey());
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: (_highlightedFaculty == faculty)
                                  ? [
                                      BoxShadow(
                                        color: facColor.withValues(alpha: 0.65),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: ChoiceChip(
                              key: key,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    faculty ==
                                            'Передовая инженерная школа «Российская электроника, инфокоммуникации и радиосвязь»'
                                        ? 'ПИШ'
                                        : faculty,
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? facColor.withValues(alpha: 0.15)
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${_getSpecCountForFaculty(faculty)}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? (theme.brightness ==
                                                      Brightness.light
                                                  ? Color.alphaBlend(
                                                      Colors.black.withValues(
                                                        alpha: 0.22,
                                                      ),
                                                      facColor,
                                                    )
                                                  : Color.alphaBlend(
                                                      Colors.white.withValues(
                                                        alpha: 0.22,
                                                      ),
                                                      facColor,
                                                    ))
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.75),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedFaculty = faculty;
                                  } else {
                                    _selectedFaculty = 'Все';
                                  }
                                });
                                _scrollToTop();
                                _scrollToFaculty(_selectedFaculty);
                                _triggerFacultyFlash(faculty);
                              },
                              selectedColor: facColor.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? facColor
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? facColor
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                width: 1,
                              ),
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),

            // Scores List
            Expanded(
              child: filteredScores.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Направления не найдены',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredScores.length,
                      itemBuilder: (context, index) {
                        final score = filteredScores[index];
                        return AdmissionScoreCard(
                          key: ValueKey(score.directionName),
                          score: score,
                          userTotal: _calculateUserTotalForDirection(score),
                          hasUserScores: _userScores.isNotEmpty,
                          isCompared: _compareList.contains(score),
                          isFacultySelected: _selectedFaculty == score.facultyName,
                          isFacultyHighlighted: _highlightedFaculty == score.facultyName,
                          onCompareToggled: (selected) {
                            setState(() {
                              if (selected) {
                                _compareList.add(score);
                              } else {
                                _compareList.remove(score);
                              }
                            });
                          },
                          onFacultyPressed: () {
                            setState(() {
                              if (_selectedFaculty == score.facultyName) {
                                _selectedFaculty = 'Все';
                              } else {
                                _selectedFaculty = score.facultyName;
                              }
                            });
                            _scrollToTop();
                            _scrollToFaculty(_selectedFaculty);
                            _triggerFacultyFlash(score.facultyName);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),

        // Floating Comparison Bottom Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          bottom: _compareList.isNotEmpty ? 16 : -100,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Выбрано: ${_compareList.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _compareList.clear();
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Очистить',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ComparisonScreen(scores: _compareList),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Сравнить',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class YearRoulette extends StatefulWidget {
  final Map<int, int> passingScores;

  const YearRoulette({super.key, required this.passingScores});

  @override
  State<YearRoulette> createState() => _YearRouletteState();
}

class _YearRouletteState extends State<YearRoulette> {
  late final PageController _pageController;
  late final List<MapEntry<int, int>> _yearsList;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _yearsList = widget.passingScores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Add 2026 with 0 (dash) if not already present
    if (_yearsList.isEmpty || _yearsList.last.key < 2026) {
      _yearsList.add(const MapEntry(2026, 0));
    }

    // Center on 2025 (second to last), not the very last
    final idx2025 = _yearsList.indexWhere((e) => e.key == 2025);
    final initialPage = idx2025 >= 0
        ? idx2025
        : (_yearsList.length > 1 ? _yearsList.length - 2 : 0);
    _currentPage = initialPage.toDouble();
    _pageController = PageController(
      viewportFraction: 0.33,
      initialPage: initialPage,
    );

    int lastSnappedPage = initialPage;
    _pageController.addListener(() {
      if (mounted) {
        final double page = _pageController.page ?? 0.0;
        setState(() {
          _currentPage = page;
        });
        final int currentSnapped = page.round();
        if (currentSnapped != lastSnappedPage) {
          lastSnappedPage = currentSnapped;
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.lightImpact();
          HapticFeedback.selectionClick();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_yearsList.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: PageView.builder(
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              controller: _pageController,
              itemCount: _yearsList.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final entry = _yearsList[index];
                final year = entry.key;
                final score = entry.value;

                final double diff = (index - _currentPage).abs();
                final double scale = (1.35 - (diff * 0.45)).clamp(0.75, 1.35);
                final double opacity = (1.0 - (diff * 0.40)).clamp(0.6, 1.0);
                final bool isCenter = diff < 0.5;

                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 150),
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 150),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              year.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: isCenter
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCenter
                                    ? theme.colorScheme.secondary
                                    : theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              score == 0 ? '—' : score.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isCenter
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.titleMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class AdmissionScoreCard extends StatefulWidget {
  final AdmissionScore score;
  final int? userTotal;
  final bool hasUserScores;
  final bool isCompared;
  final ValueChanged<bool> onCompareToggled;
  final VoidCallback? onFacultyPressed;
  final bool isFacultySelected;
  final bool isFacultyHighlighted;

  const AdmissionScoreCard({
    super.key,
    required this.score,
    required this.userTotal,
    required this.hasUserScores,
    required this.isCompared,
    required this.onCompareToggled,
    required this.isFacultySelected,
    required this.isFacultyHighlighted,
    this.onFacultyPressed,
  });

  @override
  State<AdmissionScoreCard> createState() => _AdmissionScoreCardState();
}

class _AdmissionScoreCardState extends State<AdmissionScoreCard> {
  late String _selectedForm;
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _initSelectedForm();
  }

  @override
  void didUpdateWidget(AdmissionScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _initSelectedForm();
    }
  }

  void _initSelectedForm() {
    final Set<String> allForms = {};
    if (widget.score.prices != null) allForms.addAll(widget.score.prices!.keys);
    if (widget.score.budgetSpotsMap != null) {
      allForms.addAll(widget.score.budgetSpotsMap!.keys);
    }
    if (widget.score.contractSpotsMap != null) {
      allForms.addAll(widget.score.contractSpotsMap!.keys);
    }

    final keys = allForms.toList();
    if (keys.contains('Очная')) {
      _selectedForm = 'Очная';
    } else if (keys.isNotEmpty) {
      _selectedForm = keys.first;
    } else {
      _selectedForm = 'Очная';
    }
  }

  Widget _buildBudgetSpotsSection(
    AdmissionScore score,
    ThemeData theme,
    Color facColor,
  ) {
    final totalBudget = score.budgetSpotsMap?[_selectedForm] ?? 0;
    if (totalBudget == 0) {
      return RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: 'Бюджетные места: ',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            TextSpan(
              text: 'Нет набора',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    final target = score.quotaTargetMap?[_selectedForm] ?? 0;
    final special = score.quotaSpecialMap?[_selectedForm] ?? 0;
    final separate = score.quotaSeparateMap?[_selectedForm] ?? 0;
    final mainSpots = totalBudget - (target + special + separate);

    // Вычисляем минимальный флекс для обеспечения читаемости цифр (минимум ~20px ширины)
    // Принимаем, что при ширине полосы ~300px, минимальная доля сегмента должна быть около 7%
    final minFlex = (totalBudget * 0.07).round().clamp(1, totalBudget);

    Widget buildBarSegment({
      required String category,
      required int flex,
      required int displayFlex,
      required Color color,
      required int index,
      required int totalSegments,
    }) {
      final isHighlighted = _activeCategory == category;

      // Полупрозрачный цвет внутри (как у кнопок) с масштабированием базовой прозрачности
      final fillColor = isHighlighted
          ? color.withValues(alpha: (color.a * 0.85).clamp(0.25, 1.0))
          : color.withValues(alpha: (color.a * 0.35).clamp(0.12, 1.0));

      // Край обычный (оригинальный цвет сегмента, при нажатии подсвечивается)
      final borderColor = isHighlighted
          ? color.withValues(alpha: (color.a * 1.3).clamp(0.6, 1.0))
          : color;

      return Expanded(
        flex: displayFlex,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() {
              _activeCategory = category;
            });
          },
          onTapUp: (_) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _activeCategory == category) {
                setState(() {
                  _activeCategory = null;
                });
              }
            });
          },
          onTapCancel: () {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _activeCategory == category) {
                setState(() {
                  _activeCategory = null;
                });
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: double.infinity,
            decoration: BoxDecoration(
              color: fillColor,
              border: Border(
                left: index == 0
                    ? BorderSide(color: borderColor, width: 1.0)
                    : BorderSide.none,
                right: BorderSide(color: borderColor, width: 1.0),
                top: BorderSide(color: borderColor, width: 1.0),
                bottom: BorderSide(color: borderColor, width: 1.0),
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$flex',
                    style: TextStyle(
                      color: isHighlighted
                          ? (theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87)
                          : (theme.brightness == Brightness.dark
                              ? facColor.withValues(alpha: 0.95)
                              : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), facColor)),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> activeSegments = [];
    if (target > 0) {
      activeSegments.add({
        'category': 'target',
        'flex': target,
        'displayFlex': math.max(target, minFlex),
        'color': facColor.withValues(alpha: 0.25),
      });
    }
    if (separate > 0) {
      activeSegments.add({
        'category': 'separate',
        'flex': separate,
        'displayFlex': math.max(separate, minFlex),
        'color': facColor.withValues(alpha: 0.5),
      });
    }
    if (special > 0) {
      activeSegments.add({
        'category': 'special',
        'flex': special,
        'displayFlex': math.max(special, minFlex),
        'color': facColor.withValues(alpha: 0.75),
      });
    }
    if (mainSpots > 0) {
      activeSegments.add({
        'category': 'main',
        'flex': mainSpots,
        'displayFlex': math.max(mainSpots, minFlex),
        'color': facColor,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Бюджетные места: $totalBudget',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          ),
          child: Row(
            children: [
              for (int index = 0; index < activeSegments.length; index++)
                buildBarSegment(
                  category: activeSegments[index]['category'] as String,
                  flex: activeSegments[index]['flex'] as int,
                  displayFlex: activeSegments[index]['displayFlex'] as int,
                  color: activeSegments[index]['color'] as Color,
                  index: index,
                  totalSegments: activeSegments.length,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (target > 0)
              _buildLegendItem(
                theme,
                facColor.withValues(alpha: 0.25),
                'целевая квота: $target',
                'target',
              ),
            if (separate > 0)
              _buildLegendItem(
                theme,
                facColor.withValues(alpha: 0.5),
                'отдельная квота: $separate',
                'separate',
              ),
            if (special > 0)
              _buildLegendItem(
                theme,
                facColor.withValues(alpha: 0.75),
                'особая квота: $special',
                'special',
              ),
            _buildLegendItem(
              theme,
              facColor,
              'основные места: $mainSpots',
              'main',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    ThemeData theme,
    Color color,
    String text,
    String category,
  ) {
    final isHighlighted = _activeCategory == category;
    final dotColor = isHighlighted
        ? color.withValues(alpha: (color.a * 1.3).clamp(0.0, 1.0))
        : color.withValues(alpha: color.a * 0.65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() {
          _activeCategory = category;
        });
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _activeCategory == category) {
            setState(() {
              _activeCategory = null;
            });
          }
        });
      },
      onTapCancel: () {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _activeCategory == category) {
            setState(() {
              _activeCategory = null;
            });
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted
                    ? theme.colorScheme.onSurface
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.score;
    final facColor = AppUtils.getFacultyColor(score.facultyName);

    // Находим последние 2 года с ненулевыми баллами
    final activeYears =
        score.passingScores.entries
            .where((e) => e.value > 0 && e.key <= 2025)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;
    String trendText = 'Стабильно';

    if (activeYears.length >= 2) {
      final lastVal = activeYears.last.value;
      final prevVal = activeYears[activeYears.length - 2].value;
      if (lastVal > prevVal) {
        trendIcon = Icons.trending_up;
        trendColor = const Color(0xFFEF4444); // Вырос -> Red
        trendText = 'Вырос';
      } else if (lastVal < prevVal) {
        trendIcon = Icons.trending_down;
        trendColor = const Color(0xFF10B981); // Упал -> Green
        trendText = 'Упал';
      }
    }

    final displayPrice = score.prices?[_selectedForm];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            score.directionName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: InkWell(
                                  onTap: widget.onFacultyPressed,
                                  borderRadius: BorderRadius.circular(6),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isFacultySelected
                                          ? facColor.withValues(alpha: 0.22)
                                          : facColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: widget.isFacultySelected
                                            ? facColor.withValues(alpha: 0.6)
                                            : facColor.withValues(alpha: 0.25),
                                        width: widget.isFacultySelected ? 1.2 : 1.0,
                                      ),
                                      boxShadow: widget.isFacultyHighlighted
                                          ? [
                                              BoxShadow(
                                                color: facColor.withValues(alpha: 0.6),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      score.facultyName,
                                      style: TextStyle(
                                        color: facColor,
                                        fontSize: 11,
                                        fontWeight: widget.isFacultySelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: AnimatedCompareArrows(
                        isCompared: widget.isCompared,
                      ),
                      onPressed: () {
                        widget.onCompareToggled(!widget.isCompared);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: score.subjects.map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Selector of Form of Education
          (() {
            final Set<String> availableForms = {};
            if (score.prices != null) availableForms.addAll(score.prices!.keys);
            if (score.budgetSpotsMap != null) {
              availableForms.addAll(score.budgetSpotsMap!.keys);
            }
            if (score.contractSpotsMap != null) {
              availableForms.addAll(score.contractSpotsMap!.keys);
            }

            if (availableForms.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Форма обучения:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        ...availableForms.map((form) {
                          final isSelected = _selectedForm == form;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(form),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              backgroundColor: theme.colorScheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                width: 1,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedForm = form;
                                  });
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          })(),

          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Платные места: ${score.contractSpotsMap?[_selectedForm] ?? 0}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      displayPrice ?? 'Нет набора',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: displayPrice != null
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBudgetSpotsSection(score, theme, facColor),
                const SizedBox(height: 16),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: YearRoulette(
                          key: ValueKey('${score.directionName}_roulette'),
                          passingScores: score.passingScores,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Проходные баллы прошлых лет',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(trendIcon, size: 16, color: trendColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    trendText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: trendColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCompareArrows extends StatefulWidget {
  final bool isCompared;
  final Duration duration;
  final Color? color;
  final double size;

  const AnimatedCompareArrows({
    super.key,
    required this.isCompared,
    this.duration = const Duration(milliseconds: 350),
    this.color,
    this.size = 24.0,
  });

  @override
  State<AnimatedCompareArrows> createState() => _AnimatedCompareArrowsState();
}

class _AnimatedCompareArrowsState extends State<AnimatedCompareArrows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    if (widget.isCompared) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCompareArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompared != oldWidget.isCompared) {
      if (widget.isCompared) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    final theme = Theme.of(context);
    final defaultColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final activeColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final color = widget.color ?? Color.lerp(defaultColor, activeColor, val) ?? defaultColor;

        // Параметры верхней стрелочки
        // Начальный центр вращения: (12, 8), угол: 0.0 (вправо)
        // Конечный центр вращения: (8.5, 12), угол: pi / 2 (вниз)
        final double topCenterX = 12.0 - 3.5 * val;
        final double topCenterY = 8.0 + 4.0 * val;
        final double topAngle = (math.pi / 2) * val;

        // Параметры нижней стрелочки
        // Начальный центр вращения: (12, 16), угол: pi (влево)
        // Конечный центр вращения: (15.5, 12), угол: pi / 2 (вниз)
        final double bottomCenterX = 12.0 + 3.5 * val;
        final double bottomCenterY = 16.0 - 4.0 * val;
        final double bottomAngle = math.pi - (math.pi / 2) * val;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Верхняя/Левая стрелочка
              Positioned(
                left: topCenterX - widget.size / 2,
                top: topCenterY - widget.size / 2,
                child: Transform.rotate(
                  angle: topAngle,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ArrowPainter(
                      color: color,
                      thickness: 2.2,
                      length: 13.0,
                    ),
                  ),
                ),
              ),
              // Нижняя/Правая стрелочка
              Positioned(
                left: bottomCenterX - widget.size / 2,
                top: bottomCenterY - widget.size / 2,
                child: Transform.rotate(
                  angle: bottomAngle,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ArrowPainter(
                      color: color,
                      thickness: 2.2,
                      length: 13.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double length;

  _ArrowPainter({
    required this.color,
    required this.thickness,
    required this.length,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Рисуем стрелку горизонтально, центрированно относительно (cx, cy)
    final startX = cx - length / 2;
    final endX = cx + length / 2;

    // Стержень стрелки
    canvas.drawLine(Offset(startX, cy), Offset(endX, cy), paint);

    // Наконечник стрелки (длина крыльев наконечника)
    final wingLength = length * 0.38; 
    // Угол крыльев наконечника (35 градусов)
    const wingAngle = 35 * math.pi / 180;

    final upperWing = Offset(
      endX - wingLength * math.cos(wingAngle),
      cy - wingLength * math.sin(wingAngle),
    );
    final lowerWing = Offset(
      endX - wingLength * math.cos(wingAngle),
      cy + wingLength * math.sin(wingAngle),
    );

    canvas.drawLine(Offset(endX, cy), upperWing, paint);
    canvas.drawLine(Offset(endX, cy), lowerWing, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.length != length;
  }
}
