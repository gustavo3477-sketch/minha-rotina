import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/schedule_engine.dart';

/// Nome da classe do widget nativo Android (Etapa 13) — precisa bater com
/// o `<receiver android:name="...">` do AndroidManifest.xml e com a classe
/// Kotlin em android/app/.../MinhaRotinaWidgetProvider.kt.
const _androidProviderName = 'MinhaRotinaWidgetProvider';
const _widgetDataKey = 'schedule_days';

/// Quantos dias à frente ficam disponíveis para o widget sem precisar do
/// app aberto — o suficiente para cobrir semanas sem uso, sem guardar
/// "para sempre" (mesmo espírito da seção 37, aplicado ao widget).
const _widgetWindowDays = 30;

/// Widget de tela inicial (Etapa 13, seção 42?): mostra a categoria do dia
/// (cor e nome) e a posição no ciclo, sem precisar abrir o app.
///
/// Só Android por enquanto — WidgetKit (iOS) é a Etapa 15, feita só depois
/// da preparação de ambiente da Etapa 14. Em qualquer outra plataforma
/// (inclusive Windows/web, usados só como preview de desenvolvimento),
/// todo método aqui é um no-op seguro.
///
/// A pré-computação de uma janela de dias (em vez de só "hoje") é o que
/// permite o widget continuar certo por semanas sem o app rodar: o lado
/// nativo Kotlin escolhe a data de hoje dentro dos dados já salvos —
/// [HomeWidget.scheduleWidgetUpdates] só agenda QUANDO redesenhar (via
/// AlarmManager), não recalcula nada em Dart.
class WidgetService {
  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> syncScheduleDays(ScheduleEngine engine, DateTime today) async {
    if (!_isSupportedPlatform) return;

    List<Map<String, Object?>> days;
    try {
      final end = dutil.addDaysUtc(today, _widgetWindowDays);
      days = [
        for (final day in engine.resolveRange(today, end))
          {
            'date': day.date,
            'label': day.label,
            'color': day.category.color,
            'cycleDayNumber': day.cycleDayNumber,
            'cycleDayCount': day.cycleDayCount,
          },
      ];
    } on StateError {
      // Sem escala configurada ainda — nada para o widget mostrar.
      return;
    }

    await HomeWidget.saveWidgetData<String>(_widgetDataKey, jsonEncode(days));
    await HomeWidget.updateWidget(androidName: _androidProviderName);
    await HomeWidget.scheduleWidgetUpdates([
      for (var i = 1; i <= _widgetWindowDays; i++) dutil.addDaysUtc(today, i),
    ], androidName: _androidProviderName);
  }
}
