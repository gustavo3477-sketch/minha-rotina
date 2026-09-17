// Teste de fumaça (smoke test) da Etapa 1: confirma que o app sobe sem
// erros, com o ProviderScope (Riverpod) e o tema aplicados corretamente.
//
// Testes do motor de escala (ScheduleEngine) chegam na Etapa 3, em um
// arquivo próprio (test/schedule_engine_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:minha_rotina/app/app.dart';

void main() {
  testWidgets('O app sobe e mostra a tela inicial sem erros', (tester) async {
    // Mesma inicialização feita em main() — necessária para o DateFormat
    // com locale 'pt_BR' usado na tela inicial.
    await initializeDateFormatting('pt_BR');

    await tester.pumpWidget(const ProviderScope(child: MinhaRotinaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Minha Rotina'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
