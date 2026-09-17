// Etapa 5: a tela de detalhe do dia mostra a escala daquela data e os
// compromissos cadastrados nela. Usa uma data fixa (não depende de "hoje").

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/appointment_repository.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/repositories/schedule_repository.dart';
import 'package:minha_rotina/domain/default_schedule.dart';
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/features/day_detail/day_detail_page.dart';

void main() {
  sqfliteFfiInit();

  testWidgets(
    'mostra a categoria do dia, o horário e os compromissos daquela data',
    (tester) async {
      await initializeDateFormatting('pt_BR');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async {
              final db = await openAppDatabase(
                path: inMemoryDatabasePath,
                factory: databaseFactoryFfi,
              );
              ref.onDispose(db.close);
              await CategoryRepository(db).ensureCoreCategories();
              await ScheduleRepository(db).insertVersion(
                buildDefault2x2Schedule(
                  id: 'v1',
                  referenceDate: '2026-09-16',
                  workStart: '13:00',
                  workEnd: '01:00',
                ),
              );
              await AppointmentRepository(db).insert(
                const Appointment(
                  id: 'a1',
                  kind: AppointmentKind.normal,
                  title: 'Reunião de equipe',
                  date: '2026-09-16',
                  allDay: false,
                  startTime: '09:00',
                  endTime: '10:00',
                  createdAt: '2020-01-01T00:00:00.000Z',
                  updatedAt: '2020-01-01T00:00:00.000Z',
                ),
              );
              return db;
            }),
          ],
          child: MaterialApp(
            home: DayDetailPage(date: DateTime.utc(2026, 9, 16)),
          ),
        ),
      );
      // Mesmo padrão de runAsync+pump dos outros testes de widget: sqflite_ffi
      // resolve via isolate real e precisa de tempo real (não só pump falso)
      // para cada salto assíncrono da cadeia de providers.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }

      // 16/09/2026 é a data de referência: 1º dia de trabalho do ciclo 2x2.
      expect(find.text('Trabalho'), findsOneWidget);
      expect(find.text('13:00 → 01:00'), findsOneWidget);
      expect(find.text('Dia 1 de 2'), findsOneWidget);
      expect(find.text('Reunião de equipe'), findsOneWidget);
    },
  );
}
