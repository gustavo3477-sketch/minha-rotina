// Teste de fumaça do app raiz: sem escala configurada, o app mostra a
// configuração inicial (não a tela de calendário). Usa um banco SQLite em
// memória (sqflite_common_ffi) via override do databaseProvider — a
// tela raiz não pode depender de path_provider real em teste de widget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/app/app.dart';
import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('sem escala configurada, mostra a tela de configuração inicial', (
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
        child: const MinhaRotinaApp(),
      ),
    );
    // sqflite_common_ffi resolve a abertura do banco através de uma isolate
    // real em segundo plano. Chamar tester.pump() dentro de runAsync não
    // adianta: pump() não cede tempo real ao event loop, então a resposta da
    // isolate nunca chega. O padrão que funciona é intercalar um delay real
    // (dentro de runAsync, para a I/O real avançar) com um pump normal (fora
    // dele, para a árvore de widgets refletir o novo estado) — repetido,
    // porque a cadeia de providers tem vários saltos assíncronos em série
    // (banco → categorias/escala → hasScheduleConfigured). Por isso também
    // não usamos pumpAndSettle: o CircularProgressIndicator da tela de
    // carregamento anima indefinidamente e nunca "assentaria".
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    expect(find.text('Configurar minha escala'), findsOneWidget);
    expect(find.text('Como é sua escala?'), findsOneWidget);
  });
}
