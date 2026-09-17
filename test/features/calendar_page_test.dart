// Etapa 4: com uma escala já configurada, o app deve pular direto para o
// calendário (não mostrar a configuração inicial) e a legenda deve refletir
// as categorias reais do banco.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/app/app.dart';
import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/providers.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/repositories/schedule_repository.dart';
import 'package:minha_rotina/domain/default_schedule.dart';

void main() {
  sqfliteFfiInit();

  testWidgets(
    'com escala configurada, mostra o calendário com a legenda das categorias',
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
      // porque a cadeia de providers tem vários saltos assíncronos em série.
      // Por isso também não usamos pumpAndSettle: o CircularProgressIndicator
      // da tela de carregamento anima indefinidamente e nunca "assentaria".
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }

      expect(find.text('Configurar minha escala'), findsNothing);
      expect(find.text('Trabalho'), findsOneWidget);
      expect(find.text('Folga'), findsOneWidget);
      // Cabeçalho dos dias da semana, seg-first (seção 9).
      expect(find.text('SEG'), findsOneWidget);
      expect(find.text('DOM'), findsOneWidget);
    },
  );
}
