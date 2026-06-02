// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../utils/app_utils.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'Все';
  late final List<String> _categories;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  void _scrollToCategory(String category) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void scrollAction(int attempt) {
        if (!mounted) return;
        if (category == 'Все') {
          if (_categoryScrollController.hasClients) {
            _categoryScrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
            );
          }
          return;
        }
        final key = _categoryKeys[category];
        final context = key?.currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: 0.0,
          );
        } else if (attempt < 3) {
          Future.delayed(const Duration(milliseconds: 100), () => scrollAction(attempt + 1));
        }
      }

      Future.delayed(const Duration(milliseconds: 100), () => scrollAction(1));
    });
  }

  @override
  void initState() {
    super.initState();
    // Динамически извлекаем категории из мок-активностей
    final Set<String> uniqueCats = mockActivities
        .map((act) => act.category)
        .toSet();
    _categories = ['Все', ...uniqueCats];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    if (category == 'Все') return const Color(0xFF64748B);

    // Хешируем строку категории, чтобы получить стабильный цвет
    int hash = 0;
    for (int i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Генерируем оттенок (hue) из хеша (от 0 до 360)
    final double hue = (hash.abs() % 360).toDouble();
    // Используем 65% насыщенности и 60% яркости для получения красивого пастельного цвета
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.60).toColor();
  }

  int _getActivityCountForCategory(String category) {
    if (category == 'Все') {
      return mockActivities.length;
    }
    return mockActivities.where((act) => act.category == category).length;
  }


  Widget _buildContactTile(
    BuildContext context,
    String contact,
    ThemeData theme,
  ) {
    final isPhone = RegExp(r'^\+?[0-9\s()\-]{7,}$').hasMatch(contact);
    final icon = isPhone ? Icons.phone_outlined : Icons.link;
    final color = isPhone ? theme.colorScheme.primary : const Color(0xFF06B6D4);
    final label = isPhone ? 'Телефон' : 'Ссылка';

    return InkWell(
      onTap: () => AppUtils.openContact(context, contact),
      onLongPress: () => AppUtils.copyToClipboard(context, contact, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                contact,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final filteredActivities = mockActivities.where((act) {
      final matchesCategory = _selectedCategory == 'Все' || act.category == _selectedCategory;
      final matchesSearch = act.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Панель поиска
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Поиск активностей...',
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
        // Селектор категорий
        SingleChildScrollView(
          controller: _categoryScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              final catColor = _getCategoryColor(category);
              return Padding(
                key: _categoryKeys.putIfAbsent(category, () => GlobalKey()),
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withOpacity(0.15)
                              : theme.colorScheme.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${_getActivityCountForCategory(category)}',
                          style: TextStyle(
                            color: isSelected
                                ? (theme.brightness == Brightness.light
                                    ? Color.alphaBlend(Colors.black.withOpacity(0.22), catColor)
                                    : Color.alphaBlend(Colors.white.withOpacity(0.22), catColor))
                                : theme.colorScheme.onSurface.withOpacity(0.75),
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
                        _selectedCategory = category;
                        _scrollToCategory(category);
                      } else {
                        _selectedCategory = 'Все';
                        _scrollToCategory('Все');
                      }
                    });
                  },
                  selectedColor: catColor.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? catColor
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? catColor.withOpacity(0.4)
                        : theme.colorScheme.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                  backgroundColor: theme.colorScheme.surface,
                ),
              );
            }).toList(),
          ),
        ),
        // Список активностей
        Expanded(
          child: filteredActivities.isEmpty
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
                        'Ничего не найдено',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    final catColor = _getCategoryColor(activity.category);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedCategory == activity.category) {
                                        _selectedCategory = 'Все';
                                        _scrollToCategory('Все');
                                      } else {
                                        _selectedCategory = activity.category;
                                        _scrollToCategory(activity.category);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: catColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      activity.category,
                                      style: TextStyle(
                                        color: catColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activity.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activity.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: theme.dividerColor),
                            const SizedBox(height: 8),
                            if (activity.schedule != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activity.schedule!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (activity.contact != null) ...[
                              ...activity.contact!
                                  .split(RegExp(r'[\n,;]+'))
                                  .map((c) => c.trim())
                                  .where((c) => c.isNotEmpty)
                                  .map(
                                    (c) => _buildContactTile(context, c, theme),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
