import 'package:flutter_test/flutter_test.dart';

import 'package:minha_rotina/domain/date_utils.dart';
import 'package:minha_rotina/domain/default_categories.dart';
import 'package:minha_rotina/domain/default_schedule.dart';
import 'package:minha_rotina/domain/models/category.dart';
import 'package:minha_rotina/domain/models/cycle_position.dart';
import 'package:minha_rotina/domain/models/fixed_day_rule.dart';
import 'package:minha_rotina/domain/models/schedule_exception.dart';
import 'package:minha_rotina/domain/models/schedule_version.dart';
import 'package:minha_rotina/domain/schedule_engine.dart';

void main() {
  final categories = defaultCoreCategories();

  ScheduleEngine engineFor(
    List<ScheduleVersion> versions, {
    List<ScheduleException> exceptions = const [],
  }) {
    return ScheduleEngine(
      versions: versions,
      categories: categories,
      exceptions: exceptions,
    );
  }

  group('escala 2x2 com domingo como folga fixa fora da contagem', () {
    // 2024-01-01 é uma segunda-feira (fato de calendário conhecido), então
    // 2024-01-03 é quarta-feira.
    final version = buildDefault2x2Schedule(
      id: 'v1',
      referenceDate: '2024-01-03', // quarta-feira = Trabalho (1º dia)
      workStart: '13:00',
      workEnd: '01:00',
    );
    final engine = engineFor([version]);

    test('resolve a data de referência como 1º dia de serviço', () {
      final r = engine.resolveDay(fromIsoDate('2024-01-03'));
      expect(r.category.classification, ScheduleClassification.work);
      expect(r.cycleDayNumber, 1);
      expect(r.cycleDayCount, 2);
    });

    test('segue a sequência TRABALHO, TRABALHO, FOLGA, FOLGA a partir da referência', () {
      final expected = [
        (ScheduleClassification.work, 1, 2), // qua 03/01
        (ScheduleClassification.work, 2, 2), // qui 04/01
        (ScheduleClassification.rest, 1, 2), // sex 05/01
        (ScheduleClassification.rest, 2, 2), // sáb 06/01
      ];
      final dates = ['2024-01-03', '2024-01-04', '2024-01-05', '2024-01-06'];
      for (var i = 0; i < dates.length; i++) {
        final r = engine.resolveDay(fromIsoDate(dates[i]));
        expect(r.category.classification, expected[i].$1, reason: dates[i]);
        expect(r.cycleDayNumber, expected[i].$2, reason: dates[i]);
        expect(r.cycleDayCount, expected[i].$3, reason: dates[i]);
      }
    });

    test('domingo fixo (seção 6/45): é sempre folga, mesmo caindo no meio do ciclo', () {
      final r = engine.resolveDay(fromIsoDate('2024-01-07')); // domingo
      expect(r.isFixedDay, isTrue);
      expect(r.category.classification, ScheduleClassification.rest);
    });

    test(
      'domingo NÃO incrementa o ciclo — segunda retoma de onde o sábado parou',
      () {
        final sat = engine.resolveDay(fromIsoDate('2024-01-06'));
        final mon = engine.resolveDay(fromIsoDate('2024-01-08'));
        expect(sat.category.classification, ScheduleClassification.rest);
        expect(sat.cycleDayNumber, 2);
        expect(mon.category.classification, ScheduleClassification.work);
        expect(mon.cycleDayNumber, 1);
      },
    );

    test('exemplo do briefing: sex FOLGA1/2, sáb FOLGA2/2, dom fixa (não conta), seg TRAB1/2, ter TRAB2/2', () {
      final fri = engine.resolveDay(fromIsoDate('2024-01-05'));
      final sat = engine.resolveDay(fromIsoDate('2024-01-06'));
      final sun = engine.resolveDay(fromIsoDate('2024-01-07'));
      final mon = engine.resolveDay(fromIsoDate('2024-01-08'));
      final tue = engine.resolveDay(fromIsoDate('2024-01-09'));

      expect(fri.category.classification, ScheduleClassification.rest);
      expect(fri.cycleDayNumber, 1);
      expect(sat.cycleDayNumber, 2);
      expect(sun.isFixedDay, isTrue);
      expect(mon.category.classification, ScheduleClassification.work);
      expect(mon.cycleDayNumber, 1);
      expect(tue.cycleDayNumber, 2);
    });

    test('exemplo do briefing: sáb TRAB1/2, dom fixa (não conta), seg TRAB2/2, ter FOLGA1/2', () {
      final v2 = buildDefault2x2Schedule(
        id: 'v2',
        referenceDate: '2024-01-06', // sábado = trabalho 1º dia
        workStart: '13:00',
        workEnd: '01:00',
      );
      final engine2 = engineFor([v2]);

      final sat = engine2.resolveDay(fromIsoDate('2024-01-06'));
      final sun = engine2.resolveDay(fromIsoDate('2024-01-07'));
      final mon = engine2.resolveDay(fromIsoDate('2024-01-08'));
      final tue = engine2.resolveDay(fromIsoDate('2024-01-09'));

      expect(sat.category.classification, ScheduleClassification.work);
      expect(sat.cycleDayNumber, 1);
      expect(sun.isFixedDay, isTrue);
      expect(mon.category.classification, ScheduleClassification.work);
      expect(mon.cycleDayNumber, 2);
      expect(tue.category.classification, ScheduleClassification.rest);
      expect(tue.cycleDayNumber, 1);
    });

    test('funciona corretamente para datas ANTERIORES à data de referência (seção 38)', () {
      final tue = engine.resolveDay(
        fromIsoDate('2024-01-02'),
      ); // terça, antes da referência
      expect(tue.category.classification, ScheduleClassification.rest);
      expect(tue.cycleDayNumber, 2);

      final mon = engine.resolveDay(fromIsoDate('2024-01-01'));
      expect(mon.category.classification, ScheduleClassification.rest);
      expect(mon.cycleDayNumber, 1);
    });

    test('mudança de mês, de ano e ano bissexto (seção 45): domingo sempre fixo; '
        'sem os domingos, a sequência é periódica de período 4', () {
      var cursor = fromIsoDate('2023-06-01');
      final end = fromIsoDate('2026-06-01'); // atravessa 2024, ano bissexto
      final nonSundayClassifications = <ScheduleClassification>[];

      while (!cursor.isAfter(end)) {
        final r = engine.resolveDay(cursor);
        if (cursor.weekday == 7) {
          expect(r.isFixedDay, isTrue, reason: toIsoDate(cursor));
        } else {
          expect(r.isFixedDay, isFalse, reason: toIsoDate(cursor));
          // Categorias de escala sempre têm classification — só é nula
          // para categorias de compromisso (seção 7).
          nonSundayClassifications.add(r.category.classification!);
        }
        cursor = addDaysUtc(cursor, 1);
      }

      // A fase absoluta depende de onde a varredura começou em relação à
      // âncora, mas o período de 4 precisa ser uma rotação válida de
      // [TRABALHO,TRABALHO,FOLGA,FOLGA] (nunca alternando dia a dia).
      const validRotations = [
        [
          ScheduleClassification.work,
          ScheduleClassification.work,
          ScheduleClassification.rest,
          ScheduleClassification.rest,
        ],
        [
          ScheduleClassification.work,
          ScheduleClassification.rest,
          ScheduleClassification.rest,
          ScheduleClassification.work,
        ],
        [
          ScheduleClassification.rest,
          ScheduleClassification.rest,
          ScheduleClassification.work,
          ScheduleClassification.work,
        ],
        [
          ScheduleClassification.rest,
          ScheduleClassification.work,
          ScheduleClassification.work,
          ScheduleClassification.rest,
        ],
      ];
      final firstFour = nonSundayClassifications.take(4).toList();
      // Comparação manual (não usar `contains()` do matcher aqui: ele
      // não faz igualdade profunda entre listas dentro de uma lista).
      bool sameSequence(
        List<ScheduleClassification> a,
        List<ScheduleClassification> b,
      ) {
        if (a.length != b.length) return false;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) return false;
        }
        return true;
      }

      expect(
        validRotations.any((rotation) => sameSequence(rotation, firstFour)),
        isTrue,
        reason:
            'Sequência $firstFour não é nenhuma rotação válida de TRABALHO,TRABALHO,FOLGA,FOLGA',
      );

      for (var i = 4; i < nonSundayClassifications.length; i++) {
        expect(
          nonSundayClassifications[i],
          nonSundayClassifications[i - 4],
          reason: 'posição $i vs ${i - 4}',
        );
      }
    });

    test('29 de fevereiro em ano bissexto não quebra a contagem', () {
      final d28 = engine.resolveDay(fromIsoDate('2024-02-28'));
      final d29 = engine.resolveDay(fromIsoDate('2024-02-29'));
      final d01 = engine.resolveDay(fromIsoDate('2024-03-01'));
      expect(d28.isFixedDay, isFalse);
      expect(d29.isFixedDay, isFalse);
      expect(d01.isFixedDay, isFalse);
    });

    test('jornada que atravessa a meia-noite (seção 8/45): 13:00 → 01:00', () {
      final r = engine.resolveDay(fromIsoDate('2024-01-03'));
      expect(r.startTime, '13:00');
      expect(r.endTime, '01:00');
      expect(r.crossesMidnight, isTrue);
    });

    test('exceção pontual (seção 39/45) sobrepõe o cálculo e preserva a categoria original', () {
      final exception = ScheduleException(
        id: 'exc-1',
        date: '2024-01-03', // normalmente seria trabalho 1/2
        categoryId: kExtraCategoryId,
        originalCategoryId: kWorkCategoryId,
        createdAt: '2024-01-03T00:00:00.000Z',
      );
      final engineWithException = engineFor([version], exceptions: [exception]);

      final r = engineWithException.resolveDay(fromIsoDate('2024-01-03'));
      expect(r.isException, isTrue);
      expect(r.category.id, kExtraCategoryId);
      expect(r.originalCategory?.id, kWorkCategoryId);

      // Removendo a exceção (não passando ela pro engine), o dia volta ao
      // cálculo automático — testado separadamente com resolveAutomatic.
      final automatic = engineWithException.resolveAutomatic(
        fromIsoDate('2024-01-03'),
      );
      expect(automatic.category.id, kWorkCategoryId);
    });
  });

  group('dias fixos customizáveis (não limitados a domingo)', () {
    test('permite configurar outro dia da semana como fixo fora do ciclo', () {
      final version = buildDefault2x2Schedule(
        id: 'v1',
        referenceDate: '2024-01-03',
        workStart: '13:00',
        workEnd: '01:00',
      );
      // habilita também sábado (weekday=6) como fixo.
      final updatedRules = version.fixedDayRules
          .map((r) => r.weekday == 6 ? r.copyWith(enabled: true) : r)
          .toList();
      final versionWithSaturdayFixed = version.copyWith(
        fixedDayRules: updatedRules,
      );

      final engine = engineFor([versionWithSaturdayFixed]);
      final sat = engine.resolveDay(fromIsoDate('2024-01-06'));
      expect(sat.isFixedDay, isTrue);
    });
  });

  group('versões de escala com vigência (seção 40/45: mudar de escala não afeta o histórico)', () {
    test(
      'usa a regra antiga antes de effectiveFrom e a nova a partir dela',
      () {
        final oldVersion = buildDefault2x2Schedule(
          id: 'old',
          referenceDate: '2024-01-03',
          workStart: '13:00',
          workEnd: '01:00',
        );
        final newVersion = buildDefault2x2Schedule(
          id: 'new',
          referenceDate: '2024-10-01',
          workStart: '07:00',
          workEnd: '19:00',
          effectiveFrom: '2024-10-01',
        );
        final engine = engineFor([oldVersion, newVersion]);

        final beforeChange = engine.resolveDay(fromIsoDate('2024-09-30'));
        final afterChange = engine.resolveDay(fromIsoDate('2024-10-01'));

        expect(beforeChange.startTime, '13:00');
        expect(afterChange.startTime, '07:00');
      },
    );
  });

  group('computeRunInfo — agrupamento circular de posições consecutivas', () {
    test('mescla o fim e o início do ciclo quando são da mesma categoria', () {
      const positions = [
        CyclePosition(
          id: '1',
          scheduleVersionId: 'v',
          order: 1,
          categoryId: 'rest',
        ), // FOLGA A
        CyclePosition(
          id: '2',
          scheduleVersionId: 'v',
          order: 2,
          categoryId: 'work',
        ),
        CyclePosition(
          id: '3',
          scheduleVersionId: 'v',
          order: 3,
          categoryId: 'work',
        ),
        CyclePosition(
          id: '4',
          scheduleVersionId: 'v',
          order: 4,
          categoryId: 'rest',
        ), // FOLGA B
      ];

      expect(ScheduleEngine.computeRunInfo(positions, 3), (
        dayNumber: 1,
        dayCount: 2,
      ));
      expect(ScheduleEngine.computeRunInfo(positions, 0), (
        dayNumber: 2,
        dayCount: 2,
      ));
      expect(ScheduleEngine.computeRunInfo(positions, 1), (
        dayNumber: 1,
        dayCount: 2,
      ));
      expect(ScheduleEngine.computeRunInfo(positions, 2), (
        dayNumber: 2,
        dayCount: 2,
      ));
    });
  });

  group(
    'ciclo totalmente personalizado (seção 7: nomes e horários por posição)',
    () {
      test('permite posições de trabalho com nomes e horários distintos (diurno/noturno)', () {
        const customCategories = [
          Category(
            id: 'w',
            kind: CategoryKind.schedule,
            name: 'Trabalho',
            color: '#EF4444',
            classification: ScheduleClassification.work,
          ),
          Category(
            id: 'r',
            kind: CategoryKind.schedule,
            name: 'Descanso',
            color: '#22C55E',
            classification: ScheduleClassification.rest,
          ),
        ];
        final version = ScheduleVersion(
          id: 'v1',
          name: 'Personalizada',
          effectiveFrom: '2024-01-03',
          referenceDate: '2024-01-03',
          referencePositionIndex: 0,
          cyclePositions: const [
            CyclePosition(
              id: 'p1',
              scheduleVersionId: 'v1',
              order: 1,
              categoryId: 'w',
              nameOverride: 'Diurno',
              startTime: '07:00',
              endTime: '19:00',
            ),
            CyclePosition(
              id: 'p2',
              scheduleVersionId: 'v1',
              order: 2,
              categoryId: 'w',
              nameOverride: 'Noturno',
              startTime: '19:00',
              endTime: '07:00',
            ),
            CyclePosition(
              id: 'p3',
              scheduleVersionId: 'v1',
              order: 3,
              categoryId: 'r',
            ),
            CyclePosition(
              id: 'p4',
              scheduleVersionId: 'v1',
              order: 4,
              categoryId: 'r',
            ),
          ],
          fixedDayRules: [
            for (var weekday = 1; weekday <= 7; weekday++)
              FixedDayRule(
                id: 'r$weekday',
                scheduleVersionId: 'v1',
                weekday: weekday,
                enabled: weekday == 7,
                categoryId: 'r',
              ),
          ],
        );
        final engine = ScheduleEngine(
          versions: [version],
          categories: customCategories,
          exceptions: const [],
        );

        final day1 = engine.resolveDay(fromIsoDate('2024-01-03'));
        expect(day1.label, 'Diurno');
        final day2 = engine.resolveDay(fromIsoDate('2024-01-04'));
        expect(day2.label, 'Noturno');
        expect(day2.crossesMidnight, isTrue);
      });
    },
  );

  group('findNextByClassification', () {
    test('encontra a próxima folga a partir de uma data', () {
      final version = buildDefault2x2Schedule(
        id: 'v1',
        referenceDate: '2024-01-03', // quarta = trabalho 1/2
        workStart: '13:00',
        workEnd: '01:00',
      );
      final engine = engineFor([version]);

      final nextRest = engine.findNextByClassification(
        fromIsoDate('2024-01-03'),
        ScheduleClassification.rest,
      );
      expect(nextRest?.date, '2024-01-05'); // sexta é o próximo dia de folga
    });
  });
}
