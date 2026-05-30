import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';

class CampusesScreen extends StatelessWidget {
  const CampusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: mockCampuses.length,
      itemBuilder: (context, index) {
        final campus = mockCampuses[index];
        return _CampusCard(campus: campus);
      },
    );
  }
}

class _CampusCard extends StatelessWidget {
  final Campus campus;

  const _CampusCard({required this.campus});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        key: PageStorageKey(campus.name),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: theme.colorScheme.primary),
        ),
        title: Text(
          campus.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        subtitle: InteractiveFeedback(
          borderRadius: BorderRadius.circular(8),
          activeBorderColor: theme.colorScheme.secondary,
          child: InkWell(
            onTap: () => AppUtils.openMapRoute(context, campus.address),
            onLongPress: () => AppUtils.copyToClipboard(context, campus.address, 'Адрес'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      campus.address,
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
        childrenPadding: const EdgeInsets.all(12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: const Color(0xFF64748B),
        children: [
          if (campus.faculties.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              alignment: Alignment.centerLeft,
              child: Text(
                'Факультеты и Институты:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...campus.faculties.map((faculty) => _FacultyTile(faculty: faculty)),
          ],
          if (campus.structures != null && campus.structures!.isNotEmpty) ...[
            if (campus.faculties.isNotEmpty) const Divider(height: 24),
            const _SectionTitle(
              title: 'Общеуниверситетские структуры',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 6),
            ...campus.structures!.map(
              (structure) => _InfoListItem(
                text: structure,
                icon: Icons.circle,
                iconSize: 6,
              ),
            ),
          ],
          if (campus.museums != null && campus.museums!.isNotEmpty) ...[
            if (campus.faculties.isNotEmpty ||
                (campus.structures != null && campus.structures!.isNotEmpty))
              const Divider(height: 24),
            const _SectionTitle(
              title: 'Музеи',
              icon: Icons.museum_outlined,
            ),
            const SizedBox(height: 6),
            ...campus.museums!.map(
              (museum) => _InfoListItem(
                text: museum,
                icon: Icons.museum_outlined,
                iconSize: 14,
              ),
            ),
          ],
          if (campus.extraInfo != null && campus.extraInfo!.isNotEmpty) ...[
            if (campus.faculties.isNotEmpty ||
                (campus.structures != null && campus.structures!.isNotEmpty) ||
                (campus.museums != null && campus.museums!.isNotEmpty))
              const Divider(height: 24),
            const _SectionTitle(
              title: 'Информация',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 6),
            ...campus.extraInfo!.map(
              (info) => _InfoListItem(
                text: info,
                icon: Icons.info_outline,
                iconSize: 14,
              ),
            ),
          ],
          if (campus.extraContacts != null && campus.extraContacts!.isNotEmpty) ...[
            if (campus.faculties.isNotEmpty ||
                (campus.structures != null && campus.structures!.isNotEmpty) ||
                (campus.museums != null && campus.museums!.isNotEmpty) ||
                (campus.extraInfo != null && campus.extraInfo!.isNotEmpty))
              const Divider(height: 24),
            const _SectionTitle(
              title: 'Контакты',
              icon: Icons.contact_phone_outlined,
            ),
            const SizedBox(height: 6),
            ...campus.extraContacts!.entries.map(
              (entry) => _ContactListItem(
                name: entry.key,
                value: entry.value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FacultyTile extends StatelessWidget {
  final Faculty faculty;

  const _FacultyTile({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        key: PageStorageKey(faculty.name),
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
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Text(
            faculty.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Кафедры:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final double iconSize;

  const _InfoListItem({
    required this.text,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Icon(icon, size: iconSize, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 10),
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

class _ContactListItem extends StatelessWidget {
  final String name;
  final String value;

  const _ContactListItem({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InteractiveFeedback(
        borderRadius: BorderRadius.circular(10),
        activeBorderColor: theme.colorScheme.primary,
        child: InkWell(
          onTap: () => AppUtils.openContact(context, value),
          onLongPress: () => AppUtils.copyToClipboard(context, value, name),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
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
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
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
