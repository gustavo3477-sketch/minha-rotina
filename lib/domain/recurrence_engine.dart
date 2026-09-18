import 'date_utils.dart';
import 'models/appointment.dart';
import 'models/recurrence_rule.dart';

/// Expande a ocorrência-âncora de um compromisso (seção 13) em todas as
/// datas em que ele efetivamente acontece dentro de [rangeStart, rangeEnd]
/// (inclusive nas duas pontas). Cálculo puro — nada é persistido; só a
/// ocorrência-âncora vive no banco (Etapa 2), no mesmo espírito do
/// [ScheduleEngine] (Etapa 3) para a escala.
List<DateTime> expandOccurrences(
  Appointment appointment,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final anchor = fromIsoDate(appointment.date);
  final rule = appointment.recurrence;

  if (!rule.isRecurring) {
    final inRange = !anchor.isBefore(rangeStart) && !anchor.isAfter(rangeEnd);
    return inRange ? [anchor] : [];
  }

  var effectiveEnd = rangeEnd;
  if (rule.until != null) {
    final until = fromIsoDate(rule.until!);
    if (until.isBefore(effectiveEnd)) effectiveEnd = until;
  }
  if (anchor.isAfter(effectiveEnd)) return [];

  final occurrences = <DateTime>[];
  var matchCount = 0;
  var cursor = anchor;
  while (!cursor.isAfter(effectiveEnd)) {
    if (_matchesFrequency(cursor, anchor, rule)) {
      matchCount++;
      if (rule.count != null && matchCount > rule.count!) break;
      if (!cursor.isBefore(rangeStart)) {
        occurrences.add(cursor);
      }
    }
    cursor = addDaysUtc(cursor, 1);
  }
  return occurrences;
}

bool _matchesFrequency(DateTime date, DateTime anchor, RecurrenceRule rule) {
  if (date.isBefore(anchor)) return false;

  switch (rule.frequency) {
    case RecurrenceFrequency.none:
      return date == anchor;
    case RecurrenceFrequency.daily:
      return mod(daysBetweenUtc(anchor, date), rule.interval) == 0;
    case RecurrenceFrequency.weekly:
      final weeksBetween =
          daysBetweenUtc(_mondayOfWeek(anchor), _mondayOfWeek(date)) ~/ 7;
      if (mod(weeksBetween, rule.interval) != 0) return false;
      final weekdays = rule.weekdays;
      return (weekdays == null || weekdays.isEmpty)
          ? date.weekday == anchor.weekday
          : weekdays.contains(date.weekday);
    case RecurrenceFrequency.monthly:
      if (mod(_monthsBetween(anchor, date), rule.interval) != 0) return false;
      return date.day == _clampedDay(anchor.day, date.year, date.month);
    case RecurrenceFrequency.yearly:
      if (mod(date.year - anchor.year, rule.interval) != 0) return false;
      if (date.month != anchor.month) return false;
      return date.day == _clampedDay(anchor.day, date.year, date.month);
    case RecurrenceFrequency.custom:
      // Reservado: a seção 13 não define um padrão de cálculo próprio para
      // "custom" além do que weekly+weekdays já cobre, e não é oferecido
      // como opção no formulário (Etapa 7). Nunca gera repetições.
      return false;
  }
}

DateTime _mondayOfWeek(DateTime date) => addDaysUtc(date, -(date.weekday - 1));

int _monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);

/// O dia [day] no mês [month]/[year], reduzido para o último dia do mês se
/// ele não existir (ex.: dia 31 em um mês de 30 dias) — mesma lógica que
/// [_gridEnd] em calendar_page.dart usa para achar o fim de um mês.
int _clampedDay(int day, int year, int month) {
  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  return day > lastDayOfMonth ? lastDayOfMonth : day;
}
