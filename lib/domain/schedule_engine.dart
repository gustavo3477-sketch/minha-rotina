import 'date_utils.dart';
import 'models/category.dart';
import 'models/cycle_position.dart';
import 'models/fixed_day_rule.dart';
import 'models/schedule_exception.dart';
import 'models/schedule_version.dart';
import 'schedule_day.dart';

/// O motor de escala (seção 38 do briefing).
///
/// Recebe a configuração (versões de escala, categorias, exceções) e
/// CALCULA a situação de qualquer data — passada ou futura — sob demanda.
/// Nada aqui grava nada no banco; nenhum dia é persistido individualmente
/// (isso é responsabilidade explícita do repositório da Etapa 2, que só
/// guarda a configuração e as exceções pontuais).
///
/// É uma classe pura (sem I/O): fácil de testar e reutilizar tanto na UI
/// quanto em segundo plano (ex.: cálculo do widget, Etapa 13/15).
class ScheduleEngine {
  final List<ScheduleVersion> _versions;
  final Map<String, Category> _categoriesById;
  final Map<String, ScheduleException> _exceptionsByDate;

  // Os três campos vêm de parâmetros nomeados "limpos" (versions/categories/
  // exceptions) em vez de initializing formals — os dois últimos precisam
  // de transformação (virar Map), então o primeiro fica assim só por
  // consistência de leitura.
  ScheduleEngine({
    required List<ScheduleVersion> versions,
    required List<Category> categories,
    required List<ScheduleException> exceptions,
  }) : _versions = versions, // ignore: prefer_initializing_formals
       _categoriesById = {for (final c in categories) c.id: c},
       _exceptionsByDate = {for (final e in exceptions) e.date: e};

  Category _category(String id) {
    final category = _categoriesById[id];
    if (category == null) {
      throw StateError('Categoria não encontrada: $id');
    }
    return category;
  }

  /// A versão de escala que vale para [date]: a mais recente cujo
  /// [ScheduleVersion.effectiveFrom] seja igual ou anterior a ela (seção
  /// 40 — trocar de escala não altera o histórico). Se todas as versões
  /// forem posteriores a [date], usa a mais antiga (permite calcular
  /// datas anteriores à própria data de referência).
  ScheduleVersion? pickVersionFor(String isoDate) {
    if (_versions.isEmpty) return null;
    final sorted = [..._versions]
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    var candidate = sorted.first;
    for (final version in sorted) {
      if (version.effectiveFrom.compareTo(isoDate) <= 0) {
        candidate = version;
      } else {
        break;
      }
    }
    return candidate;
  }

  /// Resolve [date] SEM considerar exceções manuais — o que a escala
  /// automática diria. Útil também para descobrir o "original" ao criar
  /// uma exceção (seção 39).
  ScheduleDay resolveAutomatic(DateTime date) {
    final iso = toIsoDate(date);
    final version = pickVersionFor(iso);
    if (version == null) {
      throw StateError('Nenhuma configuração de escala cadastrada.');
    }

    final weekday = date.weekday; // 1=segunda ... 7=domingo
    FixedDayRule? fixedRule;
    for (final rule in version.fixedDayRules) {
      if (rule.weekday == weekday && rule.enabled) {
        fixedRule = rule;
        break;
      }
    }

    if (fixedRule != null) {
      final category = _category(fixedRule.categoryId);
      return ScheduleDay(
        date: iso,
        category: category,
        label: category.name,
        isFixedDay: true,
      );
    }

    final sortedPositions = version.sortedCyclePositions;
    if (sortedPositions.isEmpty) {
      throw StateError('O ciclo da escala não possui posições configuradas.');
    }

    final fixedWeekdays = version.fixedDayRules
        .where((r) => r.enabled)
        .map((r) => r.weekday)
        .toSet();
    final referenceDate = fromIsoDate(version.referenceDate);
    final offset = computeCycleOffset(referenceDate, date, fixedWeekdays);
    final index = mod(
      version.referencePositionIndex + offset,
      sortedPositions.length,
    );
    final position = sortedPositions[index];
    final category = _category(position.categoryId);
    final runInfo = computeRunInfo(sortedPositions, index);

    return ScheduleDay(
      date: iso,
      category: category,
      label: position.nameOverride ?? category.name,
      startTime: position.startTime,
      endTime: position.endTime,
      crossesMidnight: position.crossesMidnight,
      cyclePosition: position,
      cycleDayNumber: runInfo.dayNumber,
      cycleDayCount: runInfo.dayCount,
    );
  }

  /// Resolve [date] considerando exceções manuais (prioridade 1 — seção
  /// 39). Sem exceção para o dia, cai para [resolveAutomatic].
  ScheduleDay resolveDay(DateTime date) {
    final iso = toIsoDate(date);
    final exception = _exceptionsByDate[iso];
    if (exception == null) {
      return resolveAutomatic(date);
    }

    final category = _category(exception.categoryId);
    return ScheduleDay(
      date: iso,
      category: category,
      label: category.name,
      startTime: exception.startTime,
      endTime: exception.endTime,
      isException: true,
      originalCategory: _category(exception.originalCategoryId),
    );
  }

  List<ScheduleDay> resolveRange(DateTime start, DateTime end) {
    final days = <ScheduleDay>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      days.add(resolveDay(cursor));
      cursor = addDaysUtc(cursor, 1);
    }
    return days;
  }

  /// Primeira data a partir de (e incluindo) [from] cuja classificação
  /// bate com [classification]. Usado por telas como "Próxima folga".
  ScheduleDay? findNextByClassification(
    DateTime from,
    ScheduleClassification classification, {
    int maxDays = 120,
  }) {
    var cursor = from;
    for (var i = 0; i < maxDays; i++) {
      final day = resolveDay(cursor);
      if (day.category.classification == classification) return day;
      cursor = addDaysUtc(cursor, 1);
    }
    return null;
  }

  // ---- Cálculo puro (sem estado) — expostos como estáticos para testar
  // isoladamente cada regra. ----

  /// Quantos dias com o [weekday] informado existem em [start, end]
  /// (inclusive nas duas pontas). Fórmula fechada — não itera dia a dia,
  /// então funciona bem mesmo para intervalos de muitos anos.
  static int countWeekdayOccurrences(
    DateTime start,
    DateTime end,
    int weekday,
  ) {
    final totalDays = daysBetweenUtc(start, end) + 1;
    if (totalDays <= 0) return 0;
    final shift = mod(weekday - start.weekday, 7);
    if (shift >= totalDays) return 0;
    return ((totalDays - shift - 1) ~/ 7) + 1;
  }

  static int _countCountableDays(
    DateTime start,
    DateTime end,
    Set<int> fixedWeekdays,
  ) {
    if (start.isAfter(end)) return 0;
    final totalDays = daysBetweenUtc(start, end) + 1;
    var fixedCount = 0;
    for (final weekday in fixedWeekdays) {
      fixedCount += countWeekdayOccurrences(start, end, weekday);
    }
    return totalDays - fixedCount;
  }

  /// Deslocamento (em dias "contáveis" do ciclo, ignorando os dias fixos)
  /// entre [referenceDate] e [targetDate]. Positivo se [targetDate] é
  /// posterior; negativo se anterior (seção 38: calcular datas passadas
  /// também).
  static int computeCycleOffset(
    DateTime referenceDate,
    DateTime targetDate,
    Set<int> fixedWeekdays,
  ) {
    if (daysBetweenUtc(referenceDate, targetDate) == 0) {
      return 0;
    }
    if (targetDate.isAfter(referenceDate)) {
      return _countCountableDays(
        addDaysUtc(referenceDate, 1),
        targetDate,
        fixedWeekdays,
      );
    }
    return -_countCountableDays(
      targetDate,
      addDaysUtc(referenceDate, -1),
      fixedWeekdays,
    );
  }

  /// Para a posição em [index], calcula em que ponto ela está dentro do
  /// bloco de posições consecutivas da MESMA categoria — ex.: "Dia 1 de 2"
  /// em um bloco de 2 dias de trabalho. Trata o ciclo como circular: um
  /// bloco pode "dar a volta" (última posição do array emenda com a
  /// primeira, se forem da mesma categoria).
  static ({int dayNumber, int dayCount}) computeRunInfo(
    List<CyclePosition> sortedPositions,
    int index,
  ) {
    final n = sortedPositions.length;
    if (n == 0) return (dayNumber: 1, dayCount: 1);

    final categoryId = sortedPositions[index].categoryId;
    final allSame = sortedPositions.every((p) => p.categoryId == categoryId);
    if (allSame) {
      return (dayNumber: index + 1, dayCount: n);
    }

    var start = index;
    while (sortedPositions[mod(start - 1, n)].categoryId == categoryId) {
      start = mod(start - 1, n);
      if (start == index) break;
    }

    var length = 0;
    var i = start;
    while (sortedPositions[i].categoryId == categoryId) {
      length++;
      i = mod(i + 1, n);
      if (i == start) break;
    }

    final dayNumber = mod(index - start, n) + 1;
    return (dayNumber: dayNumber, dayCount: length);
  }
}
