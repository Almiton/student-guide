// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../utils/app_utils.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String _selectedCategory = 'Все';
  late final List<String> _categories;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dynamically extract categories from mock activities
    final Set<String> uniqueCats = mockActivities
        .map((act) => act.category)
        .toSet();
    _categories = ['Все', ...uniqueCats];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    if (category == 'Все') return const Color(0xFF64748B);

    // Hash the category string to get a stable color
    int hash = 0;
    for (int i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Generate hue from hash (0 to 360)
    final double hue = (hash.abs() % 360).toDouble();
    // Use 65% saturation and 60% lightness for a beautiful pastel color
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
            const SizedBox(width: 8),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredActivities = mockActivities.where((act) {
      final matchesCategory = _selectedCategory == 'Все' || act.category == _selectedCategory;
      final matchesSearch = act.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Search bar
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
        // Category Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              final catColor = _getCategoryColor(category);
              return Padding(
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
                      } else {
                        _selectedCategory = 'Все';
                      }
                    });
                  },
                  selectedColor: catColor.withOpacity(0.2),
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
                        ? catColor
                        : theme.colorScheme.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                  backgroundColor: theme.colorScheme.surface,
                ),
              );
            }).toList(),
          ),
        ),
        // Activities List
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
                                Container(
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
                                  const SizedBox(width: 8),
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
