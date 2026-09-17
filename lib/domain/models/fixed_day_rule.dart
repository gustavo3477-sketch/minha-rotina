/// Uma regra de exceção fixa por dia da semana (seção 6 do briefing).
///
/// Exemplo real do briefing: escala 2x2, porém domingo é sempre folga e
/// NÃO entra na contagem do ciclo. [weekday] segue o padrão do Dart
/// (`DateTime.weekday`): 1 = segunda ... 7 = domingo.
class FixedDayRule {
  final String id;
  final String scheduleVersionId;

  /// 1 = segunda ... 7 = domingo (`DateTime.weekday`).
  final int weekday;

  final bool enabled;
  final String categoryId;

  const FixedDayRule({
    required this.id,
    required this.scheduleVersionId,
    required this.weekday,
    required this.enabled,
    required this.categoryId,
  });

  FixedDayRule copyWith({bool? enabled, String? categoryId}) {
    return FixedDayRule(
      id: id,
      scheduleVersionId: scheduleVersionId,
      weekday: weekday,
      enabled: enabled ?? this.enabled,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'schedule_version_id': scheduleVersionId,
      'weekday': weekday,
      'enabled': enabled ? 1 : 0,
      'category_id': categoryId,
    };
  }

  factory FixedDayRule.fromMap(Map<String, Object?> map) {
    return FixedDayRule(
      id: map['id'] as String,
      scheduleVersionId: map['schedule_version_id'] as String,
      weekday: map['weekday'] as int,
      enabled: (map['enabled'] as int) == 1,
      categoryId: map['category_id'] as String,
    );
  }
}
