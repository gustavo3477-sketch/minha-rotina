/// Uma alteração manual sobre um dia específico (seção 6 e 39 do briefing).
///
/// Exemplo: o cálculo automático diz "Trabalho", mas houve uma troca e o
/// usuário marca aquele dia como "Folga". Isso prevalece sobre o cálculo
/// SEM alterar o padrão original — remover a exceção volta a mostrar o
/// resultado automático imediatamente.
class ScheduleException {
  final String id;

  /// Data ISO (yyyy-MM-dd). Única — só pode existir uma exceção por dia.
  final String date;

  final String categoryId;

  /// O que o cálculo automático dizia antes da alteração manual —
  /// só para referência/exibição (ex.: "Escala automática: Folga").
  final String originalCategoryId;

  final String? reason;
  final String? startTime;
  final String? endTime;
  final String createdAt;

  const ScheduleException({
    required this.id,
    required this.date,
    required this.categoryId,
    required this.originalCategoryId,
    this.reason,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'category_id': categoryId,
      'original_category_id': originalCategoryId,
      'reason': reason,
      'start_time': startTime,
      'end_time': endTime,
      'created_at': createdAt,
    };
  }

  factory ScheduleException.fromMap(Map<String, Object?> map) {
    return ScheduleException(
      id: map['id'] as String,
      date: map['date'] as String,
      categoryId: map['category_id'] as String,
      originalCategoryId: map['original_category_id'] as String,
      reason: map['reason'] as String?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
