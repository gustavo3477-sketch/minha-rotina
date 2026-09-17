import 'cycle_position.dart';
import 'fixed_day_rule.dart';

/// Uma configuração de escala (seção 5/40 do briefing).
///
/// [referenceDate] + [referencePositionIndex] ancoram o ciclo: "nesta data,
/// a posição do ciclo era esta". A partir daí, qualquer outra data é
/// CALCULADA (nunca persistida dia a dia — seção 38).
///
/// [effectiveFrom] permite trocar de escala a partir de uma data sem alterar
/// o histórico anterior (seção 40): datas antes de [effectiveFrom] usam a
/// versão anterior; a partir dela, esta versão passa a valer.
///
/// [cyclePositions] e [fixedDayRules] são carregados junto pelo repositório
/// (tabelas próprias, ligadas por `schedule_version_id`) — aqui já vêm
/// "hidratados" para facilitar o uso pelo motor de escala (Etapa 3).
class ScheduleVersion {
  final String id;
  final String name;
  final String effectiveFrom;
  final String referenceDate;
  final int referencePositionIndex;
  final List<CyclePosition> cyclePositions;
  final List<FixedDayRule> fixedDayRules;

  const ScheduleVersion({
    required this.id,
    required this.name,
    required this.effectiveFrom,
    required this.referenceDate,
    required this.referencePositionIndex,
    required this.cyclePositions,
    required this.fixedDayRules,
  });

  /// [cyclePositions], já ordenadas por [CyclePosition.order].
  List<CyclePosition> get sortedCyclePositions {
    final copy = [...cyclePositions];
    copy.sort((a, b) => a.order.compareTo(b.order));
    return copy;
  }

  ScheduleVersion copyWith({
    String? name,
    String? effectiveFrom,
    String? referenceDate,
    int? referencePositionIndex,
    List<CyclePosition>? cyclePositions,
    List<FixedDayRule>? fixedDayRules,
  }) {
    return ScheduleVersion(
      id: id,
      name: name ?? this.name,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      referenceDate: referenceDate ?? this.referenceDate,
      referencePositionIndex:
          referencePositionIndex ?? this.referencePositionIndex,
      cyclePositions: cyclePositions ?? this.cyclePositions,
      fixedDayRules: fixedDayRules ?? this.fixedDayRules,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'effective_from': effectiveFrom,
      'reference_date': referenceDate,
      'reference_position_index': referencePositionIndex,
    };
  }

  factory ScheduleVersion.fromMap(
    Map<String, Object?> map, {
    List<CyclePosition> cyclePositions = const [],
    List<FixedDayRule> fixedDayRules = const [],
  }) {
    return ScheduleVersion(
      id: map['id'] as String,
      name: map['name'] as String,
      effectiveFrom: map['effective_from'] as String,
      referenceDate: map['reference_date'] as String,
      referencePositionIndex: map['reference_position_index'] as int,
      cyclePositions: cyclePositions,
      fixedDayRules: fixedDayRules,
    );
  }
}
