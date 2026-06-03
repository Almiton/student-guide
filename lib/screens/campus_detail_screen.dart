import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';

class CampusDetailScreen extends StatelessWidget {
  final Campus campus;

  const CampusDetailScreen({super.key, required this.campus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            iconTheme: IconThemeData(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Hero(
                tag: 'campus_name_${campus.name}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    campus.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Hero(
                      tag: 'campus_icon_${campus.name}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Карточка адреса
              Padding(
                padding: const EdgeInsets.all(16),
                child: InteractiveFeedback(
                  borderRadius: BorderRadius.circular(16),
                  activeBorderColor: theme.colorScheme.secondary,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () =>
                          AppUtils.openMapRoute(context, campus.address),
                      onLongPress: () => AppUtils.copyToClipboard(
                        context,
                        campus.address,
                        'Адрес',
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Адрес корпуса',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    campus.address,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Нажмите, чтобы проложить маршрут • Удерживайте для копирования',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
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
              // Заголовок раздела
              if (campus.faculties.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Факультеты и Институты',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Список факультетов
                ...campus.faculties.map(
                  (faculty) => _FacultyCard(faculty: faculty),
                ),
              ],
              if (campus.structures != null &&
                  campus.structures!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Общеуниверситетские структуры',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...campus.structures!.map(
                  (structure) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DetailInfoListItem(
                      text: structure,
                      icon: Icons.circle,
                      iconSize: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (campus.museums != null && campus.museums!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Музеи корпуса',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...campus.museums!.map(
                  (museum) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DetailInfoListItem(
                      text: museum,
                      icon: Icons.museum_outlined,
                      iconSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (campus.extraInfo != null && campus.extraInfo!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Информация',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...campus.extraInfo!.map(
                  (info) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DetailInfoListItem(
                      text: info,
                      icon: Icons.info_outline,
                      iconSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (campus.extraContacts != null &&
                  campus.extraContacts!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Контакты',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...campus.extraContacts!.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: _DetailContactListItem(
                      name: entry.key,
                      value: entry.value,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FacultyCard extends StatelessWidget {
  final Faculty faculty;

  const _FacultyCard({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faculty.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        iconColor: theme.colorScheme.secondary,
        collapsedIconColor: theme.textTheme.bodyMedium?.color?.withValues(
          alpha: 0.6,
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            faculty.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            'Кафедры:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...faculty.departments.map(
            (dept) => _DepartmentItem(department: dept),
          ),
        ],
      ),
    );
  }
}

class _DepartmentItem extends StatelessWidget {
  final Department department;

  const _DepartmentItem({required this.department});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (department.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    department.description!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (department.head != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Зав. кафедрой: ${department.head!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final double iconSize;

  const _DetailInfoListItem({
    required this.text,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Icon(
              icon,
              size: iconSize,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailContactListItem extends StatelessWidget {
  final String name;
  final String value;

  const _DetailContactListItem({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InteractiveFeedback(
      borderRadius: BorderRadius.circular(12),
      activeBorderColor: theme.colorScheme.primary,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: InkWell(
          onTap: () => AppUtils.openContact(context, value),
          onLongPress: () => AppUtils.copyToClipboard(context, value, name),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  value.contains('@')
                      ? Icons.email_outlined
                      : value.contains('http') || value.contains('.ru')
                      ? Icons.language_outlined
                      : Icons.phone_in_talk_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
