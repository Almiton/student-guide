import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';

class ComparisonScreen extends StatelessWidget {
  final List<AdmissionScore> scores;

  const ComparisonScreen({super.key, required this.scores});



  Widget _buildRowHeader(String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      alignment: Alignment.centerLeft,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCompareRow({
    required List<Widget> children,
    required String title,
    required ThemeData theme,
    required double columnWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRowHeader(title, theme),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map(
                  (child) => SizedBox(
                    width: columnWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: child,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    // Если колонок <= 2, растягиваем на всю ширину экрана (с учетом внешних и внутренних отступов).
    // Иначе используем фиксированную ширину 220dp и прокручиваем по горизонтали.
    final double columnWidth = scores.length <= 2
        ? (screenWidth - 16) / scores.length
        : 220.0;
    final double tableWidth = columnWidth * scores.length + 16;

    return Scaffold(
      appBar: AppBar(title: const Text('Сравнение направлений')),
      body: scores.isEmpty
          ? Center(
              child: Text(
                'Нет выбранных направлений для сравнения',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Названия направлений (Заголовки)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                          left: 8,
                          right: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: scores.map((score) {
                            final facColor = AppUtils.getFacultyColor(
                              score.facultyName,
                            );
                            return SizedBox(
                              width: columnWidth,
                              child: Card(
                                elevation: 2,
                                color: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: facColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: facColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                score.facultyName,
                                                style: TextStyle(
                                                  color: facColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        score.directionName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Строки сравнения: проходные баллы с 2025 по 2018 годы
                      ...[2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018].map((
                        year,
                      ) {
                        final isLatest = year == 2025;
                        return _buildCompareRow(
                          title: 'ПРОХОДНОЙ БАЛЛ $year',
                          theme: theme,
                          columnWidth: columnWidth,
                          children: scores.map((score) {
                            final val = score.passingScores[year];
                            return Center(
                              child: Text(
                                val != null && val != 0 ? val.toString() : '—',
                                style: isLatest
                                    ? theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: year >= 2023
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: year < 2023
                                            ? theme.textTheme.bodyMedium?.color
                                                  ?.withValues(alpha: 0.5)
                                            : theme.textTheme.bodyMedium?.color
                                                  ?.withValues(alpha: 0.8),
                                      ),
                              ),
                            );
                          }).toList(),
                        );
                      }),

                      // Строка сравнения: бюджетные места
                      _buildCompareRow(
                        title: 'БЮДЖЕТНЫЕ МЕСТА',
                        theme: theme,
                        columnWidth: columnWidth,
                        children: scores.map((score) {
                          final spotsText = score.budgetSpotsMap == null || score.budgetSpotsMap!.isEmpty
                              ? '0 мест'
                              : score.budgetSpotsMap!.entries.map((e) {
                                  final form = e.key;
                                  final total = e.value;
                                  final target = score.quotaTargetMap?[form] ?? 0;
                                  final special = score.quotaSpecialMap?[form] ?? 0;
                                  final separate = score.quotaSeparateMap?[form] ?? 0;
                                  final mainSpots = total - (target + special + separate);
                                  
                                  if (target > 0 || special > 0 || separate > 0) {
                                    return '$form: $total мест\n($mainSpots осн., квоты: цел. — $target, ос. — $special, отд. — $separate)';
                                  }
                                  return '$form: $total мест';
                                }).join('\n');
                          return Center(
                            child: Text(
                              spotsText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),

                      // Строка сравнения: платные места
                      _buildCompareRow(
                        title: 'ПЛАТНЫЕ МЕСТА',
                        theme: theme,
                        columnWidth: columnWidth,
                        children: scores.map((score) {
                          final spotsText = score.contractSpotsMap == null || score.contractSpotsMap!.isEmpty
                              ? '0 мест'
                              : score.contractSpotsMap!.entries
                                  .map((e) => '${e.key}: ${e.value} мест')
                                  .join('\n');
                          return Center(
                            child: Text(
                              spotsText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),

                      // Строка сравнения: стоимость обучения
                      _buildCompareRow(
                        title: 'СТОИМОСТЬ ОБУЧЕНИЯ',
                        theme: theme,
                        columnWidth: columnWidth,
                        children: scores.map((score) {
                          final pricesText = score.prices == null || score.prices!.isEmpty
                              ? 'Нет набора'
                              : score.prices!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                          return Center(
                            child: Text(
                              pricesText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),

                      // Строка сравнения: предметы ЕГЭ
                      _buildCompareRow(
                        title: 'ПРЕДМЕТЫ ЕГЭ',
                        theme: theme,
                        columnWidth: columnWidth,
                        children: scores.map((score) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: score.subjects.map((sub) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          sub,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
