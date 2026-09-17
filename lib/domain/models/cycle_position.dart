/// Uma posição dentro do ciclo de uma escala (seção 5/8 do briefing).
///
/// Exemplo de ciclo 2x2: 4 posições — Trabalho, Trabalho, Folga, Folga.
/// Cada posição pode ter nome e horário próprios (seção 7: "Cada posição do
/// ciclo pode ter configuração individual", padrão herdado do app anterior).
class CyclePosition {
  final String id;
  final String scheduleVersionId;

  /// Posição 1-based dentro do ciclo (1, 2, 3, 4...).
  final int order;

  final String categoryId;

  /// Nome específico desta posição, ex.: "Diurno" (sobrepõe o nome da
  /// categoria só para esta posição). Opcional.
  final String? nameOverride;

  final String? startTime;
  final String? endTime;

  const CyclePosition({
    required this.id,
    required this.scheduleVersionId,
    required this.order,
    required this.categoryId,
    this.nameOverride,
    this.startTime,
    this.endTime,
  });

  bool get crossesMidnight {
    if (startTime == null || endTime == null) return false;
    return endTime!.compareTo(startTime!) < 0;
  }

  CyclePosition copyWith({
    int? order,
    String? categoryId,
    String? nameOverride,
    String? startTime,
    String? endTime,
  }) {
    return CyclePosition(
      id: id,
      scheduleVersionId: scheduleVersionId,
      order: order ?? this.order,
      categoryId: categoryId ?? this.categoryId,
      nameOverride: nameOverride ?? this.nameOverride,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'schedule_version_id': scheduleVersionId,
      'order_index': order,
      'category_id': categoryId,
      'name_override': nameOverride,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory CyclePosition.fromMap(Map<String, Object?> map) {
    return CyclePosition(
      id: map['id'] as String,
      scheduleVersionId: map['schedule_version_id'] as String,
      order: map['order_index'] as int,
      categoryId: map['category_id'] as String,
      nameOverride: map['name_override'] as String?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
    );
  }
}
