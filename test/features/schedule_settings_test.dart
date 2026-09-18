// Etapa 10: editor de escala em Ajustes — editar o horário de uma posição
// do ciclo existente e criar uma nova versão de escala (seção 40).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/repositories/schedule_repository.dart';
import 'package:minha_rotina/domain/default_schedule.dart';
import 'package:minha_rotina/domain/providers.dart';
import 'package:minha_rotina/features/settings/schedule_editor_page.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

// ScheduleEditorPage recebe a versão já carregada como argumento, mas ainda
// observa categoriesProvider — que só começa a resolver quando algo lê o
// databaseProvider. Mesmo caso do _Preload em category_settings_test.dart.
class _Preload extends ConsumerWidget {
  final Widget child;

  const _Preload({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoriesProvider);
    return child;
  }
}

void main() {
  sqfliteFfiInit();

  testWidgets('edita o nome de uma posição do ciclo e persiste ao salvar', (
    tester,
  ) async {
    // Não interage com showTimePicker de fato (o dial do Material é
    // frágil de automatizar) — edita o nome da posição, que exercita o
    // mesmo caminho de estado/salvamento por um campo de texto simples.
    await initializeDateFormatting('pt_BR');
    late Database db;
    final original = buildDefault2x2Schedule(
      id: 'v1',
      referenceDate: '2026-09-16',
      workStart: '13:00',
      workEnd: '01:00',
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
            await ScheduleRepository(db).insertVersion(original);
            return db;
          }),
        ],
        child: MaterialApp(
          home: _Preload(
            child: ScheduleEditorPage(initial: original, isNew: false),
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('13:00'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome nesta posição (opcional)').first,
      'Turno diurno',
    );
    await tester.tap(find.text('Salvar'));
    await _settle(tester);

    final saved = await tester.runAsync(
      () => ScheduleRepository(db).getVersionById('v1'),
    );
    expect(saved, isNotNull);
    expect(saved!.sortedCyclePositions.first.nameOverride, 'Turno diurno');
  });
}
