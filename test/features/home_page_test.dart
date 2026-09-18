// Etapa 5: a aba Hoje mostra a escala do dia e os compromissos de hoje.
//
// Usa uma escala de ciclo único (sempre Trabalho) para que o teste seja
// determinístico independente da data real em que ele é executado — uma
// escala 2x2 dependeria de "hoje" cair em uma posição específica do ciclo,
// o que variaria a cada dia.

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
import 'package:minha_rotina/data/services/widget_service.dart';
import 'package:minha_rotina/domain/date_utils.dart' as dutil;
import 'package:minha_rotina/domain/default_categories.dart';
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/domain/models/cycle_position.dart';
import 'package:minha_rotina/domain/models/schedule_version.dart';
import 'package:minha_rotina/domain/schedule_engine.dart';
import 'package:minha_rotina/features/home/home_page.dart';

// defaultTargetPlatform é android por padrão em flutter_test — o
// ref.listen do HomePage (Etapa 13) bateria no plugin home_widget real
// sem um canal de plataforma registrado. Mesmo caso do
// _FakeNotificationService em appointment_form_page_test.dart.
class _FakeWidgetService extends WidgetService {
  @override
  Future<void> syncScheduleDays(ScheduleEngine engine, DateTime today) async {}
}

void main() {
  sqfliteFfiInit();

  DateTime todayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  testWidgets('mostra a categoria de hoje e os compromissos do dia', (
    tester,
  ) async {
    await initializeDateFormatting('pt_BR');
    final todayIso = dutil.toIsoDate(todayUtc());

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
              const ScheduleVersion(
                id: 'v1',
                name: 'Sempre trabalho',
                effectiveFrom: '2020-01-01',
                referenceDate: '2020-01-01',
                referencePositionIndex: 0,
                cyclePositions: [
                  CyclePosition(
                    id: 'p1',
                    scheduleVersionId: 'v1',
                    order: 1,
                    categoryId: kWorkCategoryId,
                  ),
                ],
                fixedDayRules: [],
              ),
            );
            await AppointmentRepository(db).insert(
              Appointment(
                id: 'a1',
                kind: AppointmentKind.normal,
                title: 'Consulta médica',
                date: todayIso,
                allDay: true,
                createdAt: '2020-01-01T00:00:00.000Z',
                updatedAt: '2020-01-01T00:00:00.000Z',
              ),
            );
            return db;
          }),
          widgetServiceProvider.overrideWithValue(_FakeWidgetService()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    // Ver comentário equivalente em calendar_page_test.dart: sqflite_ffi
    // resolve via isolate real, então é preciso alternar delay real
    // (dentro de runAsync) com pump normal para os providers em cadeia
    // resolverem e a árvore de widgets refletir o resultado.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    expect(find.text('Trabalho'), findsOneWidget);
    expect(find.text('Consulta médica'), findsOneWidget);
    // Ciclo de uma posição só (sempre Trabalho) nunca chega em Folga.
    expect(find.text('Próxima folga'), findsNothing);
  });
}
