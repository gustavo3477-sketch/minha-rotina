import 'default_categories.dart';
import 'models/cycle_position.dart';
import 'models/fixed_day_rule.dart';
import 'models/schedule_version.dart';

/// Constrói a escala padrão do briefing (seção 6): 2 dias de trabalho, 2 de
/// folga, com domingo como folga fixa que NÃO entra na contagem do ciclo.
///
/// Usada nos testes do motor de escala e, futuramente, como ponto de
/// partida sugerido no onboarding (seção 41).
ScheduleVersion buildDefault2x2Schedule({
  required String id,
  required String referenceDate,
  required String workStart,
  required String workEnd,
  String? effectiveFrom,
  String name = 'Minha escala',
  String workCategoryId = kWorkCategoryId,
  String restCategoryId = kRestCategoryId,
}) {
  // Observação: CyclePosition.crossesMidnight é calculado automaticamente
  // a partir de startTime/endTime — não precisa (e não deve) ser passado.
  return ScheduleVersion(
    id: id,
    name: name,
    effectiveFrom: effectiveFrom ?? referenceDate,
    referenceDate: referenceDate,
    referencePositionIndex: 0,
    cyclePositions: [
      CyclePosition(
        id: '$id-pos-1',
        scheduleVersionId: id,
        order: 1,
        categoryId: workCategoryId,
        startTime: workStart,
        endTime: workEnd,
      ),
      CyclePosition(
        id: '$id-pos-2',
        scheduleVersionId: id,
        order: 2,
        categoryId: workCategoryId,
        startTime: workStart,
        endTime: workEnd,
      ),
      CyclePosition(
        id: '$id-pos-3',
        scheduleVersionId: id,
        order: 3,
        categoryId: restCategoryId,
      ),
      CyclePosition(
        id: '$id-pos-4',
        scheduleVersionId: id,
        order: 4,
        categoryId: restCategoryId,
      ),
    ],
    fixedDayRules: [
      for (var weekday = 1; weekday <= 7; weekday++)
        FixedDayRule(
          id: '$id-rule-$weekday',
          scheduleVersionId: id,
          weekday: weekday,
          enabled: weekday == 7, // 7 = domingo
          categoryId: restCategoryId,
        ),
    ],
  );
}
