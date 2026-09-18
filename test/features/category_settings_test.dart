// Etapa 10: gestão de categorias em Ajustes — criar, editar, e o bloqueio
// de excluir uma categoria de escala que está em uso.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/repositories/schedule_repository.dart';
import 'package:minha_rotina/domain/models/category.dart';
import 'package:minha_rotina/domain/models/cycle_position.dart';
import 'package:minha_rotina/domain/models/schedule_version.dart';
import 'package:minha_rotina/domain/providers.dart';
import 'package:minha_rotina/features/settings/category_form_page.dart';
import 'package:minha_rotina/features/settings/category_list_page.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

// CategoryFormPage por si só não observa nenhum provider ligado ao banco
// (não precisa, para criar uma categoria) — então, sem isto, o banco só
// começaria a abrir no instante do toque em "Salvar", e a leitura síncrona
// do repositório dentro de _save() aconteceria antes do Future resolver.
// Na tela real isso nunca ocorre porque sempre se chega aqui a partir de
// CategoryListPage, que já força essa resolução antes.
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

  testWidgets('cria uma categoria de compromisso nova', (tester) async {
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
          home: _Preload(
            child: const CategoryFormPage(kind: CategoryKind.appointment),
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Academia');
    await tester.tap(find.text('Salvar'));
    await _settle(tester);

    final saved = await tester.runAsync(() => CategoryRepository(db).getAll());
    expect(saved!.any((c) => c.name == 'Academia'), isTrue);
  });

  testWidgets('lista mostra categorias essenciais sem opção de excluir', (
    tester,
  ) async {
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
            return db;
          }),
        ],
        child: const MaterialApp(home: CategoryListPage()),
      ),
    );
    await _settle(tester);

    expect(find.text('Trabalho'), findsOneWidget);
    expect(find.text('Essencial — não pode excluir'), findsWidgets);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('bloqueia excluir categoria de escala em uso na escala atual', (
    tester,
  ) async {
    await initializeDateFormatting('pt_BR');
    late Database db;
    const customCategory = Category(
      id: 'custom-1',
      kind: CategoryKind.schedule,
      name: 'Meio período',
      color: '#0EA5E9',
      classification: ScheduleClassification.work,
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
            await CategoryRepository(db).insert(customCategory);
            await ScheduleRepository(db).insertVersion(
              const ScheduleVersion(
                id: 'v1',
                name: 'Escala',
                effectiveFrom: '2026-01-01',
                referenceDate: '2026-01-01',
                referencePositionIndex: 0,
                cyclePositions: [
                  CyclePosition(
                    id: 'p1',
                    scheduleVersionId: 'v1',
                    order: 1,
                    categoryId: 'custom-1',
                  ),
                ],
                fixedDayRules: [],
              ),
            );
            return db;
          }),
        ],
        child: const MaterialApp(home: CategoryListPage()),
      ),
    );
    await _settle(tester);

    expect(find.text('Meio período'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Meio período'),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await _settle(tester);

    expect(find.text('Categoria em uso'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await _settle(tester);

    final remaining = await tester.runAsync(
      () => CategoryRepository(db).getById('custom-1'),
    );
    expect(remaining, isNotNull);
  });
}
