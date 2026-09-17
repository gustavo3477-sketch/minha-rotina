// Etapa 6: criar, editar e excluir compromissos pelo formulário.
//
// Verifica o efeito no banco diretamente (via o mesmo Database usado pelo
// override) em vez de depender do Navigator.pop — a página é a única rota
// da árvore de teste, então "pop" não tem para onde voltar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/appointment_repository.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/features/appointment_form/appointment_form_page.dart';

Future<void> _settle(WidgetTester tester) async {
  // Mesmo padrão dos outros testes de widget: sqflite_common_ffi resolve via
  // isolate real, então é preciso alternar delay real (dentro de runAsync)
  // com pump normal para os providers em cadeia resolverem.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

// Ler direto do banco depois de interagir com o formulário passa pelo mesmo
// problema de zona de tempo falso — sem runAsync aqui, esta consulta real ao
// sqflite_common_ffi nunca retorna dentro do teste.
Future<List<Appointment>> _fetchForDate(
  WidgetTester tester,
  Database db,
  String date,
) async {
  final result = await tester.runAsync(
    () => AppointmentRepository(db).getForDate(date),
  );
  return result!;
}

void main() {
  sqfliteFfiInit();

  testWidgets('cria um novo compromisso', (tester) async {
    await initializeDateFormatting('pt_BR');
    late Database db;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async {
            db = await openAppDatabase(
              path: inMemoryDatabasePath,
              factory: databaseFactoryFfi,
            );
            ref.onDispose(db.close);
            await CategoryRepository(db).ensureCoreCategories();
            return db;
          }),
        ],
        child: MaterialApp(
          home: AppointmentFormPage(initialDate: DateTime.utc(2026, 9, 20)),
        ),
      ),
    );
    await _settle(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Consulta odontológica',
    );
    await tester.tap(find.text('Salvar'));
    await _settle(tester);

    final saved = await _fetchForDate(tester, db, '2026-09-20');
    expect(saved, hasLength(1));
    expect(saved.first.title, 'Consulta odontológica');
    expect(saved.first.kind, AppointmentKind.normal);
  });

  testWidgets('edita um compromisso existente', (tester) async {
    await initializeDateFormatting('pt_BR');
    late Database db;
    const existing = Appointment(
      id: 'a1',
      kind: AppointmentKind.normal,
      title: 'Reunião',
      date: '2026-09-20',
      allDay: true,
      createdAt: '2020-01-01T00:00:00.000Z',
      updatedAt: '2020-01-01T00:00:00.000Z',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async {
            db = await openAppDatabase(
              path: inMemoryDatabasePath,
              factory: databaseFactoryFfi,
            );
            ref.onDispose(db.close);
            await CategoryRepository(db).ensureCoreCategories();
            await AppointmentRepository(db).insert(existing);
            return db;
          }),
        ],
        child: MaterialApp(
          home: AppointmentFormPage(
            initialDate: DateTime.utc(2026, 9, 20),
            existing: existing,
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Reunião'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Reunião de equipe',
    );
    await tester.tap(find.text('Salvar'));
    await _settle(tester);

    final saved = await _fetchForDate(tester, db, '2026-09-20');
    expect(saved, hasLength(1));
    expect(saved.first.id, 'a1');
    expect(saved.first.title, 'Reunião de equipe');
  });

  testWidgets('exclui um compromisso existente', (tester) async {
    await initializeDateFormatting('pt_BR');
    late Database db;
    const existing = Appointment(
      id: 'a1',
      kind: AppointmentKind.normal,
      title: 'Reunião',
      date: '2026-09-20',
      allDay: true,
      createdAt: '2020-01-01T00:00:00.000Z',
      updatedAt: '2020-01-01T00:00:00.000Z',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async {
            db = await openAppDatabase(
              path: inMemoryDatabasePath,
              factory: databaseFactoryFfi,
            );
            ref.onDispose(db.close);
            await CategoryRepository(db).ensureCoreCategories();
            await AppointmentRepository(db).insert(existing);
            return db;
          }),
        ],
        child: MaterialApp(
          home: AppointmentFormPage(
            initialDate: DateTime.utc(2026, 9, 20),
            existing: existing,
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.text('Excluir'));
    await _settle(tester);

    final saved = await _fetchForDate(tester, db, '2026-09-20');
    expect(saved, isEmpty);
  });
}
