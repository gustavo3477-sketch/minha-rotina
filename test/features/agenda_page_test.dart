// Etapa 8: a Agenda lista compromissos futuros (dentro da janela padrão) e
// a busca encontra compromissos de qualquer data, mesmo fora da janela.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/appointment_repository.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/domain/date_utils.dart' as dutil;
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/features/agenda/agenda_page.dart';

DateTime _todayUtc() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

void main() {
  sqfliteFfiInit();

  testWidgets(
    'lista compromissos futuros dentro da janela e agrupa por "Hoje"',
    (tester) async {
      await initializeDateFormatting('pt_BR');
      final today = _todayUtc();

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
              await AppointmentRepository(db).insert(
                Appointment(
                  id: 'a1',
                  kind: AppointmentKind.normal,
                  title: 'Consulta odontológica',
                  date: dutil.toIsoDate(today),
                  allDay: true,
                  createdAt: '2020-01-01T00:00:00.000Z',
                  updatedAt: '2020-01-01T00:00:00.000Z',
                ),
              );
              return db;
            }),
          ],
          child: const MaterialApp(home: AgendaPage()),
        ),
      );
      await _settle(tester);

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Consulta odontológica'), findsOneWidget);
    },
  );

  testWidgets(
    'busca encontra compromissos fora da janela padrão da agenda (seção 43)',
    (tester) async {
      await initializeDateFormatting('pt_BR');
      final today = _todayUtc();
      final farPast = dutil.addDaysUtc(today, -300);

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
              await AppointmentRepository(db).insert(
                Appointment(
                  id: 'a1',
                  kind: AppointmentKind.normal,
                  title: 'Arquivo antigo',
                  date: dutil.toIsoDate(farPast),
                  allDay: true,
                  createdAt: '2020-01-01T00:00:00.000Z',
                  updatedAt: '2020-01-01T00:00:00.000Z',
                ),
              );
              return db;
            }),
          ],
          child: const MaterialApp(home: AgendaPage()),
        ),
      );
      await _settle(tester);

      // Fora da janela padrão: não aparece na lista de próximos compromissos.
      expect(find.text('Arquivo antigo'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Arquivo');
      await _settle(tester);

      expect(find.text('Arquivo antigo'), findsOneWidget);
    },
  );
}
