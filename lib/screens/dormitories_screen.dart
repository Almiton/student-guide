// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';

class DormitoriesScreen extends StatefulWidget {
  const DormitoriesScreen({super.key});

  @override
  State<DormitoriesScreen> createState() => _DormitoriesScreenState();
}

class _DormitoriesScreenState extends State<DormitoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredDormitories = mockDormitories.where((dormitory) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();

      // Поиск по названию, адресу или описанию самого общежития
      final matchesDorm = dormitory.name.toLowerCase().contains(query) ||
          dormitory.address.toLowerCase().contains(query) ||
          dormitory.description.toLowerCase().contains(query);
      if (matchesDorm) return true;

      // Проверяем, есть ли места для этого факультета (с учетом сокращений!)
      final hasFacultySpots = dormitory.facultySpots != null &&
          dormitory.facultySpots!.keys.any((key) {
            return AppUtils.matchFaculty(key, query) ||
                   key.toLowerCase().contains(query) ||
                   key.toLowerCase().contains('все факультеты') ||
                   key.toLowerCase().contains('общее распределение');
          });

      return hasFacultySpots;
    }).toList();

    return Column(
      children: [
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
              hintText: 'Поиск общежития, адреса или факультета...',
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        Expanded(
          child: filteredDormitories.isEmpty
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
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filteredDormitories.length,
                  itemBuilder: (context, index) {
                    final dormitory = filteredDormitories[index];
                    return _DormitoryCard(dormitory: dormitory);
                  },
                ),
        ),
      ],
    );
  }
}

class _DormitoryCard extends StatefulWidget {
  final Dormitory dormitory;

  const _DormitoryCard({required this.dormitory});

  @override
  State<_DormitoryCard> createState() => _DormitoryCardState();
}

class _DormitoryCardState extends State<_DormitoryCard> {
  String _selectedForm = 'Очная';

  @override
  void initState() {
    super.initState();
    _initSelectedForm();
  }

  @override
  void didUpdateWidget(_DormitoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dormitory != widget.dormitory) {
      _initSelectedForm();
    }
  }

  void _initSelectedForm() {
    final prices = widget.dormitory.prices;
    if (prices != null && prices.isNotEmpty) {
      if (prices.containsKey('Очная')) {
        _selectedForm = 'Очная';
      } else {
        _selectedForm = prices.keys.first;
      }
    } else {
      _selectedForm = 'Очная';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dormitory = widget.dormitory;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.hotel,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dormitory.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Адрес
                InteractiveFeedback(
                  borderRadius: BorderRadius.circular(8),
                  activeBorderColor: theme.colorScheme.secondary,
                  child: InkWell(
                    onTap: () =>
                        AppUtils.openMapRoute(context, dormitory.address),
                    onLongPress: () => AppUtils.copyToClipboard(
                      context,
                      dormitory.address,
                      'Адрес',
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dormitory.address,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Телефон
                if (dormitory.phone != null) ...[
                  const SizedBox(height: 6),
                  InteractiveFeedback(
                    borderRadius: BorderRadius.circular(8),
                    activeBorderColor: theme.colorScheme.primary,
                    child: InkWell(
                      onTap: () =>
                          AppUtils.openDialer(context, dormitory.phone!),
                      onLongPress: () => AppUtils.copyToClipboard(
                        context,
                        dormitory.phone!,
                        'Телефон',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dormitory.phone!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Заведующая
                if (dormitory.manager != null) ...[
                  const SizedBox(height: 6),
                  InteractiveFeedback(
                    borderRadius: BorderRadius.circular(8),
                    activeBorderColor: theme.colorScheme.secondary,
                    child: InkWell(
                      onLongPress: () => AppUtils.copyToClipboard(
                        context,
                        dormitory.manager!,
                        'ФИО заведующей',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Заведующая: ${dormitory.manager!}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ExpansionTile(
            key: PageStorageKey('details_${dormitory.name}'),
            title: Text(
              'Места и стоимость',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.colorScheme.secondary,
            children: [
              if (dormitory.facultySpots != null &&
                  dormitory.facultySpots!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Распределение мест:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(() {
                        final sortedEntries = dormitory.facultySpots!.entries
                            .toList();
                        sortedEntries.sort((a, b) {
                          final aKey = a.key.toLowerCase();
                          final bKey = b.key.toLowerCase();
                          final aIsRepair = aKey.contains('ремонт');
                          final bIsRepair = bKey.contains('ремонт');
                          final aIsReserve = aKey.contains('резерв');
                          final bIsReserve = bKey.contains('резерв');

                          if (aIsRepair && !bIsRepair) return 1;
                          if (!aIsRepair && bIsRepair) return -1;

                          if (aIsReserve && !bIsReserve) {
                            if (bIsRepair) return -1;
                            return 1;
                          }
                          if (!aIsReserve && bIsReserve) {
                            if (aIsRepair) return 1;
                            return -1;
                          }

                          return b.value.compareTo(a.value);
                        });
                        return sortedEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key
                                        .replaceAll(
                                          RegExp(r'\s*\(.*?\)\s*'),
                                          '',
                                        )
                                        .trim(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppUtils.getPluralSpots(entry.value),
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      })(),
                    ],
                  ),
                ),
              ],
              (() {
                final Set<String> availableForms = {};
                if (dormitory.prices != null) {
                  availableForms.addAll(dormitory.prices!.keys);
                }

                if (availableForms.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dormitory.facultySpots != null &&
                          dormitory.facultySpots!.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 24),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Стоимость проживания:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        key: PageStorageKey('scroll_${dormitory.name}'),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            ...availableForms.map((form) {
                              final isSelected = _selectedForm == form;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  key: ValueKey(form),
                                  showCheckmark: false,
                                  label: Text(form),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.primary
                                      .withOpacity(0.15),
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
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.1),
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
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Итого:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              dormitory.prices?[_selectedForm] ?? 'Не указана',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],
          ),
        ],
      ),
    );
  }
}
