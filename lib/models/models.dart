class Department {
  final String name;
  final String? description;
  final String? head;

  Department({
    required this.name,
    this.description,
    this.head,
  });
}

class Faculty {
  final String name;
  final String description;
  final List<Department> departments;

  Faculty({
    required this.name,
    required this.description,
    required this.departments,
  });
}

class Campus {
  final String name;
  final String address;
  final List<Faculty> faculties;
  final List<String>? structures;
  final List<String>? museums;
  final List<String>? extraInfo;
  final Map<String, String>? extraContacts;

  Campus({
    required this.name,
    required this.address,
    required this.faculties,
    this.structures,
    this.museums,
    this.extraInfo,
    this.extraContacts,
  });
}

class Dormitory {
  final String name;
  final String address;
  final String description;
  final String? phone;
  final String? manager;
  final Map<String, int>? facultySpots;
  final Map<String, String>? prices;

  Dormitory({
    required this.name,
    required this.address,
    required this.description,
    this.phone,
    this.manager,
    this.facultySpots,
    this.prices,
  });
}

class StudentActivity {
  final String title;
  final String category; // 'Студактив', 'Студотряд', 'Секция', 'Клуб'
  final String description;
  final String? schedule;
  final String? contact;

  StudentActivity({
    required this.title,
    required this.category,
    required this.description,
    this.schedule,
    this.contact,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

class AdmissionScore {
  final String directionName;
  final String facultyName;
  final List<String> subjects;
  final Map<int, int> passingScores;
  final Map<String, int>? budgetSpotsMap;
  final Map<String, int>? contractSpotsMap;
  final Map<String, int>? quotaTargetMap;
  final Map<String, int>? quotaSpecialMap;
  final Map<String, int>? quotaSeparateMap;
  final Map<String, String>? prices;

  AdmissionScore({
    required this.directionName,
    required this.facultyName,
    required this.subjects,
    required this.passingScores,
    int? budgetSpots,
    int? contractSpots,
    Map<String, int>? budgetSpotsMap,
    Map<String, int>? contractSpotsMap,
    this.quotaTargetMap,
    this.quotaSpecialMap,
    this.quotaSeparateMap,
    this.prices,
  })  : budgetSpotsMap = budgetSpotsMap ?? (budgetSpots != null ? {'Очная': budgetSpots} : null),
        contractSpotsMap = contractSpotsMap ?? (contractSpots != null ? {'Очная': contractSpots} : null);

  int get budgetSpots => budgetSpotsMap?['Очная'] ?? budgetSpotsMap?.values.firstOrNull ?? 0;
  int get contractSpots => contractSpotsMap?['Очная'] ?? contractSpotsMap?.values.firstOrNull ?? 0;
  String? get price => prices?['Очная'] ?? prices?.values.firstOrNull;
}
