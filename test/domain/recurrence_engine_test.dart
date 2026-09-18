import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/domain/date_utils.dart';
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/domain/models/recurrence_rule.dart';
import 'package:minha_rotina/domain/recurrence_engine.dart';

Appointment _appointment({
  required String date,
  RecurrenceRule recurrence = const RecurrenceRule(),
}) {
  return Appointment(
    id: 'a1',
    kind: AppointmentKind.normal,
    title: 'Teste',
    date: date,
    allDay: true,
    recurrence: recurrence,
    createdAt: '2020-01-01T00:00:00.000Z',
    updatedAt: '2020-01-01T00:00:00.000Z',
  );
}

List<String> _iso(List<DateTime> dates) => dates.map(toIsoDate).toList();

void main() {
  group('sem recorrência', () {
    test('só ocorre na própria data-âncora, se estiver no intervalo', () {
      final appointment = _appointment(date: '2026-03-10');

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-01'),
            fromIsoDate('2026-03-31'),
          ),
        ),
        ['2026-03-10'],
      );
      expect(
        expandOccurrences(
          appointment,
          fromIsoDate('2026-04-01'),
          fromIsoDate('2026-04-30'),
        ),
        isEmpty,
      );
    });
  });

  group('diária', () {
    test('todos os dias quando interval=1', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-10'),
            fromIsoDate('2026-03-13'),
          ),
        ),
        ['2026-03-10', '2026-03-11', '2026-03-12', '2026-03-13'],
      );
    });

    test('a cada 3 dias quando interval=3', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-10'),
            fromIsoDate('2026-03-19'),
          ),
        ),
        ['2026-03-10', '2026-03-13', '2026-03-16', '2026-03-19'],
      );
    });

    test('nunca antes da data-âncora', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
      );

      expect(
        expandOccurrences(
          appointment,
          fromIsoDate('2026-03-01'),
          fromIsoDate('2026-03-09'),
        ),
        isEmpty,
      );
    });
  });

  group('semanal', () {
    test('sem dias da semana explícitos, repete no mesmo dia da âncora', () {
      // 2026-03-10 é uma terça-feira.
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-01'),
            fromIsoDate('2026-03-31'),
          ),
        ),
        ['2026-03-10', '2026-03-17', '2026-03-24', '2026-03-31'],
      );
    });

    test('com dias da semana específicos (seção 13: determinados dias)', () {
      // segunda(1) e quinta(4), a partir de uma terça-feira (âncora).
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: {1, 4},
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-01'),
            fromIsoDate('2026-03-20'),
          ),
        ),
        // A segunda da mesma semana da âncora (09/03) já passou antes da
        // âncora e não conta; a quinta da mesma semana (12/03) conta.
        ['2026-03-12', '2026-03-16', '2026-03-19'],
      );
    });

    test('quinzenal (interval=2) pula uma semana inteira', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-01'),
            fromIsoDate('2026-04-10'),
          ),
        ),
        ['2026-03-10', '2026-03-24', '2026-04-07'],
      );
    });
  });

  group('mensal', () {
    test('mesmo dia do mês, todo mês', () {
      final appointment = _appointment(
        date: '2026-01-31',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-01-01'),
            fromIsoDate('2026-04-30'),
          ),
        ),
        // Fevereiro e abril não têm dia 31 — reduz para o último dia do mês.
        ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30'],
      );
    });
  });

  group('anual', () {
    test('mesmo dia e mês, todo ano — trata 29/02 em ano não bissexto', () {
      final appointment = _appointment(
        date: '2024-02-29',
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.yearly),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2024-01-01'),
            fromIsoDate('2027-01-01'),
          ),
        ),
        ['2024-02-29', '2025-02-28', '2026-02-28'],
      );
    });
  });

  group('until e count', () {
    test('until interrompe a repetição numa data (inclusive)', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          until: '2026-03-13',
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-10'),
            fromIsoDate('2026-03-31'),
          ),
        ),
        ['2026-03-10', '2026-03-11', '2026-03-12', '2026-03-13'],
      );
    });

    test('count limita o número total de ocorrências desde a âncora', () {
      final appointment = _appointment(
        date: '2026-03-10',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          count: 3,
        ),
      );

      expect(
        _iso(
          expandOccurrences(
            appointment,
            fromIsoDate('2026-03-10'),
            fromIsoDate('2026-03-31'),
          ),
        ),
        ['2026-03-10', '2026-03-11', '2026-03-12'],
      );
    });
  });
}
