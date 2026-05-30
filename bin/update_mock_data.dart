import 'dart:convert';
import 'dart:io';

// --- Unicode escape-последовательности кириллицы ---
final String uOchnaya = '\u041e\u0447\u043d\u0430\u044f'; // Очная
final String uZaochnaya = '\u0417\u0430\u043e\u0447\u043d\u0430\u044f'; // Заочная
final String uOchnoZaochnaya = '\u041e\u0447\u043d\u043e-\u0437\u0430\u043e\u0447\u043d\u0430\u044f'; // Очно-заочная

// --- Поиск факультета в CountPaid.txt ---
String? detectFaculty(String line) {
  final lower = line.toLowerCase();
  if (lower.contains('\u0438\u043d\u0436\u0435\u043d\u0435\u0440\u043d\u0430\u044f \u0448\u043a\u043e\u043b\u0430')) {
    return 'Передовая инженерная школа «Российская электроника, инфокоммуникации и радиосвязь»';
  }
  if (lower.contains('\u0431\u0438\u043e\u043b\u043e\u0433\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Медико-биологический';
  if (lower.contains('\u0433\u0435\u043e\u0433\u0440\u0430\u0444\u0438\u0438')) return 'Географии и туризма';
  if (lower.contains('\u0433\u0435\u043e\u043b\u043e\u0433\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Геологический';
  if (lower.contains('\u0436\u0443\u0440\u043d\u0430\u043b\u0438\u0441\u0442')) return 'Журналистики';
  if (lower.contains('\u0438\u0441\u0442\u043e\u0440\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Исторический';
  if (lower.contains('\u043a\u043e\u043c\u043f\u044c\u044e\u0442\u0435\u0440\u043d\u044b\u0445 \u043d\u0430\u0443\u043a')) return 'ФКН';
  if (lower.contains('\u043c\u0430\u0442\u0435\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438\u0439 \u0444\u0430\u043a\u0443\u043b\u044c\u0442\u0435\u0442')) return 'Математический';
  if (lower.contains('\u043c\u0435\u0436\u0434\u0443\u043d\u0430\u0440\u043e\u0434\u043d\u044b\u0445 \u043e\u0442\u043d\u043e\u0448\u0435\u043d\u0438\u0439')) return 'ФМО';
  if (lower.contains('\u043f\u0440\u0438\u043a\u043b\u0430\u0434\u043d\u043e\u0439 \u043c\u0430\u0442\u0435\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'ПММ';
  if (lower.contains('\u0440\u043e\u043c\u0430\u043d\u043e-\u0433\u0435\u0440\u043c\u0430\u043d\u0441\u043a\u043e\u0439')) return 'РГФ';
  if (lower.contains('\u044d\u043a\u043e\u043d\u043e\u043c\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Экономический';
  if (lower.contains('\u044e\u0440\u0438\u0434\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Юридический';
  if (lower.contains('\u044f\u0434\u0435\u0440\u043d\u044b\u0435 \u0444\u0438\u0437\u0438\u043a\u0430')) return 'Физический';
  if (lower.contains('\u0444\u0438\u0437\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Физический';
  if (lower.contains('\u0444\u0438\u043b\u043e\u043b\u043e\u0433\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Филологический';
  if (lower.contains('\u0444\u0438\u043b\u043e\u0441\u043e\u0444\u0438\u0438 \u0438 \u043f\u0441\u0438\u0445\u043e\u043b\u043e\u0433\u0438\u0438')) return 'Философии и психологии';
  if (lower.contains('\u0445\u0438\u043c\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Химический';
  if (lower.contains('\u0444\u0430\u0440\u043c\u0430\u0446\u0435\u0432\u0442\u0438\u0447\u0435\u0441\u043a\u0438\u0439')) return 'Фармацевтический';
  if (lower.contains('\u0431\u043e\u0440\u0438\u0441\u043e\u0433\u043b\u0435\u0431\u0441\u043a\u0438\u0439')) return 'Борисоглебский филиал';
  return null;
}

// --- Нормализация названия специальности для сопоставления ---
String normalizeSpecName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('педагогическое образование (с двумя профилями подготовки)', 'педагогическое образование')
      .replaceAll('пед. образование', 'педагогическое образование')
      .trim();
}

// --- Парсинг основных таблиц бюджетных мест ---
Map<String, List<Map<String, int>>> parseTable(List<String> lines, int start, int end) {
  final Map<String, List<Map<String, int>>> resultByCode = {};
  final codeRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{2}\b');
  final numRegex = RegExp(r'\b\d+\b');

  for (int i = start; i < end; i++) {
    final line = lines[i];
    final codeMatch = codeRegex.firstMatch(line);
    if (codeMatch != null) {
      final code = codeMatch.group(0)!;
      final middleDigits = int.tryParse(code.split('.')[1]);
      if (middleDigits != 3 && middleDigits != 5) {
        continue;
      }

      final codeStart = codeMatch.start;
      final codeEnd = codeMatch.end;

      final matches = numRegex.allMatches(line);
      final remaining = <RegExpMatch>[];
      for (final m in matches) {
        if (m.start >= codeStart && m.end <= codeEnd) {
          continue;
        }
        remaining.add(m);
      }

      final Map<String, int> spots = {};
      for (final m in remaining) {
        final val = int.parse(m.group(0)!);
        final startIdx = m.start;

        String form = uOchnaya;
        if (startIdx < 95) {
          form = uOchnaya;
        } else if (startIdx < 105) {
          form = uOchnoZaochnaya;
        } else {
          form = uZaochnaya;
        }
        spots[form] = val;
      }

      resultByCode.putIfAbsent(code, () => []).add(spots);
    }
  }
  return resultByCode;
}

// --- Парсинг таблиц квот с умным сопоставлением ---
Map<String, List<Map<String, int>>> parseQuotaTableWithMapping(
    List<String> lines,
    int start,
    int end,
    Map<String, List<Map<String, int>>> mainBudgetSpots) {
  
  final Map<String, List<Map<String, int>>> resultByCode = {};
  final codeRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{2}\b');
  final numRegex = RegExp(r'\b\d+\b');

  final Map<String, int> codeOccurrence = {};

  for (int i = start; i < end; i++) {
    final line = lines[i];
    final codeMatch = codeRegex.firstMatch(line);
    if (codeMatch != null) {
      final code = codeMatch.group(0)!;
      final middleDigits = int.tryParse(code.split('.')[1]);
      if (middleDigits != 3 && middleDigits != 5) {
        continue;
      }

      final codeStart = codeMatch.start;
      final codeEnd = codeMatch.end;

      final matches = numRegex.allMatches(line);
      final remaining = <RegExpMatch>[];
      for (final m in matches) {
        if (m.start >= codeStart && m.end <= codeEnd) {
          continue;
        }
        remaining.add(m);
      }

      final occurrence = codeOccurrence[code] ?? 0;
      codeOccurrence[code] = occurrence + 1;

      Map<String, int> mainSpots = {};
      final mainList = mainBudgetSpots[code];
      if (mainList != null && occurrence < mainList.length) {
        mainSpots = mainList[occurrence];
      }

      final List<String> availableForms = mainSpots.keys.toList();
      availableForms.sort((a, b) {
        const order = {'Очная': 0, 'Очно-заочная': 1, 'Заочная': 2};
        return (order[a] ?? 9).compareTo(order[b] ?? 9);
      });

      final Map<String, int> quotaSpots = {};
      for (int k = 0; k < remaining.length; k++) {
        final val = int.parse(remaining[k].group(0)!);
        if (k < availableForms.length) {
          final form = availableForms[k];
          quotaSpots[form] = val;
        } else {
          quotaSpots['Очная'] = val;
        }
      }

      resultByCode.putIfAbsent(code, () => []).add(quotaSpots);
    }
  }
  return resultByCode;
}

// --- Парсинг целевых квот ---
Map<String, List<Map<String, int>>> parseTargetQuotas(List<String> lines, int start, int end) {
  final Map<String, List<Map<String, int>>> resultByCode = {};
  final codeRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{2}\b');
  final numRegex = RegExp(r'\b\d+\b');

  final Map<String, int> sums = {};
  for (int i = start; i < end; i++) {
    final line = lines[i];
    final codeMatch = codeRegex.firstMatch(line);
    if (codeMatch != null) {
      final code = codeMatch.group(0)!;
      final middleDigits = int.tryParse(code.split('.')[1]);
      if (middleDigits != 3 && middleDigits != 5) {
        continue;
      }

      final matches = numRegex.allMatches(line).toList();
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        if (lastMatch.start > codeMatch.end) {
          final val = int.parse(lastMatch.group(0)!);
          sums[code] = (sums[code] ?? 0) + val;
        }
      }
    }
  }

  for (final entry in sums.entries) {
    resultByCode[entry.key] = [
      {uOchnaya: entry.value}
    ];
  }

  return resultByCode;
}

// --- Функции нормализации и сопоставления для проходных баллов ---
String normalizeString(String s) {
  return s.toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Set<String> getWords(String s) {
  final norm = normalizeString(s);
  return norm.split(' ')
      .map((w) => w.replaceAll(RegExp(r'[^\wа-яё]'), ''))
      .where((w) => w.length > 2 && w != 'для' && w != 'при' && w != 'под' && w != 'или' && w != 'вгу')
      .toSet();
}

bool isFacultyCompatible(String mockFac, String fileFac) {
  final m = mockFac.toLowerCase();
  final f = fileFac.toLowerCase();

  if (m == 'пмм' && (f.contains('прикладной математики') || f.contains('пмм'))) return true;
  if (m == 'математический' && f.contains('математический')) return true;
  if (m == 'фкн' && (f.contains('компьютерных наук') || f.contains('фкн'))) return true;
  if (m == 'физический' && f.contains('физический')) return true;
  if (m == 'химический' && f.contains('химический')) return true;
  if (m == 'геологический' && f.contains('геологический')) return true;
  if (m == 'географии и туризма' && (f.contains('географии') || f.contains('туризма'))) return true;
  if (m == 'медико-биологический' && (f.contains('биолого-почвенный') || f.contains('медико-биологический'))) return true;
  if (m.contains('философии') && f.contains('философии')) return true;
  if (m == 'экономический' && f.contains('экономический')) return true;
  if (m == 'фмо' && (f.contains('международных отношений') || f.contains('фмо'))) return true;
  if (m == 'исторический' && f.contains('исторический')) return true;
  if (m == 'юридический' && f.contains('юридический')) return true;
  if (m == 'журналистики' && f.contains('журналистики')) return true;
  if (m == 'филологический' && f.contains('филологический')) return true;
  if (m == 'ргф' && (f.contains('романо-германской') || f.contains('ргф'))) return true;
  if (m == 'фармацевтический' && f.contains('фармацевтический')) return true;
  
  if (m == 'передовая инженерная школа «российская электроника, инфокоммуникации и радиосвязь»') {
    if (f.contains('передовая инженерная школа') || 
        f.contains('электроники, систем связи') ||
        f.contains('компьютерных наук') || 
        f.contains('физический')
    ) {
      return true;
    }
  }

  if (f.contains(m) || m.contains(f)) return true;
  return false;
}

bool isSpecCompatible(String mockSpec, String fileSpec) {
  final m = normalizeString(mockSpec);
  final f = normalizeString(fileSpec);

  final cleanFileSpec = f.replaceAll(RegExp(r'\(учебный военный центр\)'), '').trim();

  if (m == cleanFileSpec) return true;
  if (cleanFileSpec.contains(m) || m.contains(cleanFileSpec)) return true;

  final mWords = getWords(m);
  final fWords = getWords(cleanFileSpec);

  if (mWords.isEmpty || fWords.isEmpty) return false;

  if (mWords.every((w) => fWords.contains(w)) || fWords.every((w) => mWords.contains(w))) {
    return true;
  }

  final intersection = mWords.intersection(fWords);
  if (intersection.length >= 3) return true;
  if (mWords.length <= 2 && intersection.length == mWords.length) return true;

  return false;
}

// --- Форматирование чисел для цен ---
String _formatNumber(String s) {
  if (s.length == 6) {
    return '${s.substring(0, 3)}\u00A0${s.substring(3)}';
  } else if (s.length == 5) {
    return '${s.substring(0, 2)}\u00A0${s.substring(2)}';
  }
  return s;
}

void main() {
  print('=== ЗАПУСК ОБЪЕДИНЕННОГО ПАРСЕРА ДАННЫХ ВГУ ===');

  // 1. Валидация входных файлов
  final priceFile = File('PriceEducation2026.txt');
  final freeFile = File('CountFree.txt');
  final paidFile = File('CountPaid.txt');
  final scoresDir = Directory('PDF_text');
  final mockFile = File('lib/data/mock_data.dart');

  if (!priceFile.existsSync()) {
    print('Ошибка: Файл PriceEducation2026.txt не найден!');
    return;
  }
  if (!freeFile.existsSync()) {
    print('Ошибка: Файл CountFree.txt не найден!');
    return;
  }
  if (!paidFile.existsSync()) {
    print('Ошибка: Файл CountPaid.txt не найден!');
    return;
  }
  if (!scoresDir.existsSync()) {
    print('Ошибка: Папка PDF_text не найдена!');
    return;
  }
  if (!mockFile.existsSync()) {
    print('Ошибка: Файл lib/data/mock_data.dart не найден!');
    return;
  }

  // ==========================================
  // ЭТАП 1: Парсинг стоимостей обучения
  // ==========================================
  print('-> Парсинг стоимости обучения (PriceEducation2026.txt)...');
  final priceContent = priceFile.readAsStringSync();
  final app1End = priceContent.indexOf('Приложение № 2');
  if (app1End == -1) {
    print('Ошибка: Не удалось найти "Приложение № 2" в файле стоимостей.');
    return;
  }
  final app1Content = priceContent.substring(0, app1End);
  final pricePages = app1Content.split(RegExp(r'[\x0c]'));
  final Map<String, Map<String, String>> directionPrices = {};
  final codeRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{2}\b');
  final priceRegex = RegExp(r'\b\d{5,6}\b');

  for (int p = 0; p < pricePages.length; p++) {
    final page = pricePages[p];
    final lines = page.split('\n');

    int c1 = -1, c2 = -1, c3 = -1;
    for (final line in lines) {
      final match = RegExp(r'\b1\s+2\s+3\b').firstMatch(line) ?? 
                    RegExp(r'\b1\s+2\s+3_?\b').firstMatch(line) ?? 
                    RegExp(r'\b1\s+2\s+3\s*$').firstMatch(line);
      if (match != null) {
        c1 = line.indexOf('1');
        c2 = line.indexOf('2');
        c3 = line.indexOf('3');
        break;
      }
      
      final c1Idx = line.indexOf(RegExp(r'\b1\b'));
      final c2Idx = line.indexOf(RegExp(r'\b2\b'));
      final c3Idx = line.indexOf(RegExp(r'\b3\b'));
      if (c1Idx != -1 && c2Idx != -1 && c3Idx != -1 && c1Idx < c2Idx && c2Idx < c3Idx) {
        c1 = c1Idx; c2 = c2Idx; c3 = c3Idx;
        break;
      }
    }

    if (c1 == -1) {
      c1 = 50; c2 = 60; c3 = 70;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final codeMatch = codeRegex.firstMatch(line);
      if (codeMatch != null) {
        final code = codeMatch.group(0)!;
        final sLines = [line];
        if (i + 1 < lines.length && !codeRegex.hasMatch(lines[i + 1])) {
          sLines.add(lines[i + 1]);
        }

        final Map<String, String> prices = {};
        for (final sLine in sLines) {
          final priceMatches = priceRegex.allMatches(sLine);
          for (final pm in priceMatches) {
            final val = pm.group(0)!;
            final startIdx = pm.start;

            final d1 = (startIdx - c1).abs();
            final d2 = (startIdx - c2).abs();
            final d3 = (startIdx - c3).abs();

            String form = 'Очная';
            if (d2 < d1 && d2 < d3) {
              form = 'Очно-заочная';
            } else if (d3 < d1 && d3 < d2) {
              form = 'Заочная';
            }
            
            final formattedVal = '${_formatNumber(val)} руб/год';
            prices[form] = formattedVal;
          }
        }

        if (prices.isNotEmpty) {
          if (directionPrices.containsKey(code)) {
            directionPrices[code]!.addAll(prices);
          } else {
            directionPrices[code] = prices;
          }
        }
      }
    }
  }
  print('Успешно: Распарсены цены для ${directionPrices.length} направлений.');

  // ==========================================
  // ЭТАП 2: Парсинг бюджетных/платных мест и квот
  // ==========================================
  print('-> Парсинг количества мест и квот (CountFree.txt, CountPaid.txt)...');
  final freeLines = freeFile.readAsLinesSync();
  int mainSectionStart = freeLines.indexWhere((l) => l.contains('1. Программы бакалавриата и специалитета'));
  if (mainSectionStart == -1) mainSectionStart = 0;
  int mainSectionEnd = freeLines.indexWhere((l) => l.contains('2. Программы магистратуры'));
  if (mainSectionEnd == -1) mainSectionEnd = freeLines.length;

  int separateSectionStart = freeLines.indexWhere((l) => l.contains('ОТДЕЛЬНАЯ КВОТА'));
  int separateSectionEnd = freeLines.indexWhere((l) => l.contains('ОСОБАЯ КВОТА'));

  int specialSectionStart = freeLines.indexWhere((l) => l.contains('ОСОБАЯ КВОТА'));
  int specialSectionEnd = freeLines.indexWhere((l) => l.contains('ЦЕЛЕВАЯ КВОТА'));

  int targetSectionStart = freeLines.indexWhere((l) => l.contains('ЦЕЛЕВАЯ КВОТА'));
  int targetSectionEnd = freeLines.indexWhere((l) => l.contains('Приложение'));
  if (targetSectionEnd == -1) targetSectionEnd = freeLines.length;

  final budgetSpotsByCode = parseTable(freeLines, mainSectionStart, mainSectionEnd);
  final separateSpotsByCode = parseQuotaTableWithMapping(freeLines, separateSectionStart, separateSectionEnd, budgetSpotsByCode);
  final specialSpotsByCode = parseQuotaTableWithMapping(freeLines, specialSectionStart, specialSectionEnd, budgetSpotsByCode);
  final targetSpotsByCode = parseTargetQuotas(freeLines, targetSectionStart, targetSectionEnd);

  final paidLines = paidFile.readAsLinesSync();
  final Map<String, Map<String, Map<String, int>>> contractSpotsData = {};
  String currentPaidFaculty = '';
  String lastSpecialty = '';

  for (int i = 0; i < paidLines.length; i++) {
    final line = paidLines[i];
    if (line.trim().isEmpty) continue;

    final detectedFaculty = detectFaculty(line);
    if (detectedFaculty != null) {
      currentPaidFaculty = detectedFaculty;
      lastSpecialty = '';
    }

    if (currentPaidFaculty.isEmpty) continue;

    final parts = line.trim().split(RegExp(r'\s{2,}'));
    if (parts.length >= 2) {
      String? formText;
      int? spotsVal;

      for (int k = 0; k < parts.length; k++) {
        final p = parts[k].toLowerCase();
        if (p.contains('очная') || p.contains('заочная') || p.contains('очно-заочная') || p.contains('очно-')) {
          formText = parts[k];
          for (int m = k; m < parts.length; m++) {
            final numMatch = RegExp(r'\b\d+\b').firstMatch(parts[m]);
            if (numMatch != null) {
              spotsVal = int.parse(numMatch.group(0)!);
              break;
            }
          }
          break;
        }
      }

      if (formText != null && spotsVal != null) {
        String form = uOchnaya;
        final formLower = formText.toLowerCase();
        if (formLower.contains('очно-заочная') || formLower.contains('очно-')) {
          form = uOchnoZaochnaya;
        } else if (formLower.contains('заочная')) {
          form = uZaochnaya;
        } else if (formLower.contains('очная')) {
          form = uOchnaya;
        }

        String specialty = '';
        if (parts.length >= 4) {
          specialty = parts[1];
        } else if (parts.length == 3) {
          if (detectFaculty(parts[0]) != null) {
            specialty = lastSpecialty;
          } else {
            specialty = parts[0];
          }
        } else {
          specialty = lastSpecialty;
        }

        if (specialty.isEmpty) {
          specialty = lastSpecialty;
        } else {
          int j = i + 1;
          while (j < paidLines.length) {
            final nextLine = paidLines[j];
            final nextParts = nextLine.trim().split(RegExp(r'\s{2,}'));
            if (nextParts.length == 1 && 
                !nextParts[0].toLowerCase().contains('очная') && 
                !nextParts[0].toLowerCase().contains('заочная') &&
                detectFaculty(nextParts[0]) == null) {
              specialty += ' ${nextParts[0]}';
              j++;
            } else {
              break;
            }
          }
          lastSpecialty = specialty;
        }

        contractSpotsData.putIfAbsent(currentPaidFaculty, () => {});
        contractSpotsData[currentPaidFaculty]!.putIfAbsent(normalizeSpecName(specialty), () => {});
        contractSpotsData[currentPaidFaculty]![normalizeSpecName(specialty)]![form] = spotsVal;
      }
    }
  }
  print('Успешно: Собраны данные о бюджетных и коммерческих местах.');

  // ==========================================
  // ЭТАП 3: Парсинг проходных баллов из папки PDF_text/
  // ==========================================
  print('-> Парсинг проходных баллов прошлых лет (PDF_text/)...');
  final Map<int, Map<String, Map<String, int>>> parsedScores = {};
  final scoreFiles = scoresDir.listSync().whereType<File>().where((f) => f.path.endsWith('.txt')).toList();

  for (final file in scoreFiles) {
    final filename = file.uri.pathSegments.last;
    final yearMatch = RegExp(r'\d{4}').firstMatch(filename);
    if (yearMatch == null) continue;
    final year = int.parse(yearMatch.group(0)!);

    parsedScores[year] = {};
    final lines = file.readAsLinesSync();
    String currentFaculty = 'Unknown';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final normalizedLine = normalizeString(line);
      final isFaculty = normalizedLine.contains('факультет') || 
                        normalizedLine.contains('институт') || 
                        normalizedLine.contains('департамент') ||
                        normalizedLine.contains('школа') ||
                        normalizedLine.contains('геологический') ||
                        normalizedLine.contains('биолого-почвенный');
      
      final scoreMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(line);
      if (isFaculty && scoreMatch == null) {
        currentFaculty = line;
        if (i + 1 < lines.length) {
          final nextLine = lines[i+1].trim();
          final nextNorm = normalizeString(nextLine);
          if (nextLine.isNotEmpty && 
              !nextNorm.contains('факультет') && 
              !nextNorm.contains('департамент') && 
              !RegExp(r'\d+$').hasMatch(nextLine) &&
              nextNorm.length < 50) {
            currentFaculty += ' ' + nextLine;
            i++;
          }
        }
        continue;
      }

      if (scoreMatch != null) {
        final spec = scoreMatch.group(1)!.trim();
        final score = int.parse(scoreMatch.group(2)!);
        parsedScores[year]!.putIfAbsent(currentFaculty, () => {});
        parsedScores[year]![currentFaculty]![spec] = score;
      } else {
        if (i + 1 < lines.length) {
          final nextLine = lines[i+1].trim();
          final nextMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(nextLine);
          if (nextMatch != null) {
            final combinedSpec = line + ' ' + nextMatch.group(1)!.trim();
            final score = int.parse(nextMatch.group(2)!);
            parsedScores[year]!.putIfAbsent(currentFaculty, () => {});
            parsedScores[year]![currentFaculty]![combinedSpec] = score;
            i++;
          }
        }
      }
    }
  }
  print('Успешно: Распарсены баллы за ${parsedScores.length} лет.');

  // ==========================================
  // ЭТАП 4: Обновление файла mock_data.dart
  // ==========================================
  print('-> Обновление файла lib/data/mock_data.dart...');
  final mockContent = mockFile.readAsStringSync();
  final parts = mockContent.split('AdmissionScore(');
  final newParts = <String>[parts[0]];

  final Map<String, int> usedBudgetIndices = {};
  final Map<String, int> usedSeparateIndices = {};
  final Map<String, int> usedSpecialIndices = {};
  final Map<String, int> usedTargetIndices = {};

  int updatedCount = 0;

  for (int i = 1; i < parts.length; i++) {
    final part = parts[i];
    final dirMatch = RegExp(r"directionName:\s*'([^']+)'").firstMatch(part);
    final facMatch = RegExp(r"facultyName:\s*'([^']+)'").firstMatch(part);

    if (dirMatch == null || facMatch == null) {
      newParts.add(part);
      continue;
    }

    final fullDirName = dirMatch.group(1)!;
    final facultyName = facMatch.group(1)!;

    final codeRegexLocal = RegExp(r'^\d{2}\.\d{2}\.\d{2}');
    final codeMatch = codeRegexLocal.firstMatch(fullDirName);
    if (codeMatch == null) {
      newParts.add(part);
      continue;
    }

    final code = codeMatch.group(0)!;
    final specName = fullDirName.replaceFirst(RegExp(r'^\d{2}\.\d{2}\.\d{2}\s+'), '');

    // 1. Получение цен
    final pricesMap = directionPrices[code] ?? {};

    // 2. Получение бюджетных мест и квот
    final Map<String, int> budgetMap = {};
    final spotsList = budgetSpotsByCode[code];
    final idx = usedBudgetIndices[code] ?? 0;
    if (spotsList != null && idx < spotsList.length) {
      budgetMap.addAll(spotsList[idx]);
      usedBudgetIndices[code] = idx + 1;
    }

    final Map<String, int> separateMap = {};
    final separateList = separateSpotsByCode[code];
    final sepIdx = usedSeparateIndices[code] ?? 0;
    if (separateList != null && sepIdx < separateList.length) {
      separateMap.addAll(separateList[sepIdx]);
      usedSeparateIndices[code] = sepIdx + 1;
    }

    final Map<String, int> specialMap = {};
    final specialList = specialSpotsByCode[code];
    final specIdx = usedSpecialIndices[code] ?? 0;
    if (specialList != null && specIdx < specialList.length) {
      specialMap.addAll(specialList[specIdx]);
      usedSpecialIndices[code] = specIdx + 1;
    }

    final Map<String, int> targetMap = {};
    final targetList = targetSpotsByCode[code];
    final tarIdx = usedTargetIndices[code] ?? 0;
    if (targetList != null && tarIdx < targetList.length) {
      targetMap.addAll(targetList[tarIdx]);
      usedTargetIndices[code] = tarIdx + 1;
    }

    // Получение контрактных мест
    final Map<String, int> contractMap = {};
    String? matchedPaidFaculty;
    for (final paidFac in contractSpotsData.keys) {
      if (paidFac.toLowerCase() == facultyName.toLowerCase() ||
          (facultyName == 'ПММ' && paidFac.contains('прикладной математики')) ||
          (facultyName == 'ФКН' && paidFac.contains('компьютерных наук')) ||
          (facultyName == 'РГФ' && paidFac.contains('романо-германской')) ||
          (facultyName == 'ФМО' && paidFac.contains('международных отношений')) ||
          paidFac.toLowerCase().contains(facultyName.toLowerCase()) ||
          facultyName.toLowerCase().contains(paidFac.toLowerCase())) {
        matchedPaidFaculty = paidFac;
        break;
      }
    }

    if (matchedPaidFaculty != null) {
      final normSpec = normalizeSpecName(specName);
      String? matchedSpecKey;
      for (final specKey in contractSpotsData[matchedPaidFaculty]!.keys) {
        if (specKey == normSpec || specKey.contains(normSpec) || normSpec.contains(specKey)) {
          matchedSpecKey = specKey;
          break;
        }
      }

      if (matchedSpecKey != null) {
        final parsedSpotsMap = contractSpotsData[matchedPaidFaculty]![matchedSpecKey]!;
        if (parsedSpotsMap.isNotEmpty) {
          contractMap.addAll(parsedSpotsMap);
        }
      }
    }

    // 3. Получение и слияние проходных баллов
    final scoresMatch = RegExp(r'passingScores:\s*(\{.*?\})').firstMatch(part);
    final Map<int, int> currentScores = {};
    if (scoresMatch != null) {
      final scoresStr = scoresMatch.group(1)!;
      final scoreMatches = RegExp(r'(\d{4}):\s*(\d+)').allMatches(scoresStr);
      for (final sm in scoreMatches) {
        currentScores[int.parse(sm.group(1)!)] = int.parse(sm.group(2)!);
      }
    }

    final Map<int, int> newScores = Map.from(currentScores);
    for (final year in parsedScores.keys) {
      final yearData = parsedScores[year]!;
      int? foundScore;

      for (final fileFac in yearData.keys) {
        if (!isFacultyCompatible(facultyName, fileFac)) continue;

        for (final fileSpec in yearData[fileFac]!.keys) {
          if (isSpecCompatible(specName, fileSpec)) {
            foundScore = yearData[fileFac]![fileSpec];
            break;
          }
        }
        if (foundScore != null) break;
      }

      if (foundScore != null) {
        newScores[year] = foundScore;
      }
    }

    // Очищаем старые поля из блока
    var cleanedPart = part;
    cleanedPart = cleanedPart.replaceAll(RegExp(r'budgetSpots(Map)?:\s*(\{.*?\}|\d+),?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'contractSpots(Map)?:\s*(\{.*?\}|\d+),?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'quotaTargetMap:\s*\{.*?\},?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'quotaSpecialMap:\s*\{.*?\},?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'quotaSeparateMap:\s*\{.*?\},?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'prices:\s*\{.*?\},?\n?\s*', dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r"price:\s*'[^']+',?\n?\s*", dotAll: true), '');
    cleanedPart = cleanedPart.replaceAll(RegExp(r'passingScores:\s*\{[^}]*\},?\n?\s*', dotAll: true), '');
    
    // Схлопываем лишние пустые строки
    cleanedPart = cleanedPart.replaceAll(RegExp(r'\n\s*\n+'), '\n');

    // Форматируем новые мапы для вставки
    final List<String> scoresEntries = [];
    for (int y = 2015; y <= 2025; y++) {
      scoresEntries.add('$y: ${newScores[y] ?? 0}');
    }
    final String passingScoresStr = scoresEntries.join(', ');

    final String budgetSpotsMapStr = budgetMap.entries.map((e) => "'${e.key}': ${e.value}").join(', ');
    final String contractSpotsMapStr = contractMap.entries.map((e) => "'${e.key}': ${e.value}").join(', ');
    final String targetSpotsMapStr = targetMap.entries.map((e) => "'${e.key}': ${e.value}").join(', ');
    final String specialSpotsMapStr = specialMap.entries.map((e) => "'${e.key}': ${e.value}").join(', ');
    final String separateSpotsMapStr = separateMap.entries.map((e) => "'${e.key}': ${e.value}").join(', ');
    final String pricesStr = pricesMap.entries.map((e) => "'${e.key}': '${e.value}'").join(', ');

     // Находим закрывающую скобку блока
    final insertIndex = cleanedPart.lastIndexOf(')');
    if (insertIndex != -1) {
      final beforeStr = cleanedPart.substring(0, insertIndex).trimRight();
      final afterStr = cleanedPart.substring(insertIndex);
      
      final fieldsBuffer = StringBuffer();
      fieldsBuffer.write('\n    passingScores: {$passingScoresStr},');
      if (budgetMap.isNotEmpty) fieldsBuffer.write('\n    budgetSpotsMap: {$budgetSpotsMapStr},');
      if (contractMap.isNotEmpty) fieldsBuffer.write('\n    contractSpotsMap: {$contractSpotsMapStr},');
      if (targetMap.isNotEmpty) fieldsBuffer.write('\n    quotaTargetMap: {$targetSpotsMapStr},');
      if (specialMap.isNotEmpty) fieldsBuffer.write('\n    quotaSpecialMap: {$specialSpotsMapStr},');
      if (separateMap.isNotEmpty) fieldsBuffer.write('\n    quotaSeparateMap: {$separateSpotsMapStr},');
      if (pricesMap.isNotEmpty) fieldsBuffer.write('\n    prices: {$pricesStr},');
      fieldsBuffer.write('\n  ');
      
      cleanedPart = beforeStr + fieldsBuffer.toString() + afterStr;
      updatedCount++;
    }

    newParts.add(cleanedPart);
  }

  final updatedContent = newParts.join('AdmissionScore(');
  mockFile.writeAsStringSync(updatedContent);

  print('=== Успешно: Обновлено $updatedCount направлений в mock_data.dart ===');
}
