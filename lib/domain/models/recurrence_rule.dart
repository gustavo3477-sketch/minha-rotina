/// Frequência de repetição de um compromisso (seção 13 do briefing).
///
/// "Toda semana" e "determinados dias da semana" usam o MESMO valor
/// ([RecurrenceFrequency.weekly]): sem [RecurrenceRule.weekdays] explícito,
/// repete no mesmo dia da semana da data-âncora; com [RecurrenceRule.weekdays],
/// repete nos dias informados. Evita um valor de enum redundante para o
/// mesmo mecanismo de cálculo.
enum RecurrenceFrequency { none, daily, weekly, monthly, yearly, custom }

/// Regra de recorrência de um compromisso.
///
/// Guardada como colunas da própria tabela `appointments` (não em uma tabela
/// separada): é um atributo 1-para-1 do compromisso, não uma entidade com
/// vida própria — criar uma tabela separada duplicaria estrutura sem motivo
/// (seção 52: evitar sistemas duplicados desnecessários).
class RecurrenceRule {
  final RecurrenceFrequency frequency;

  /// A cada quantas unidades da [frequency] repete (padrão 1). Ex.:
  /// frequency=weekly, interval=2 → quinzenal.
  final int interval;

  /// Dias da semana (1=segunda...7=domingo), só para [RecurrenceFrequency.weekly].
  final Set<int>? weekdays;

  /// Data final da repetição (ISO), opcional.
  final String? until;

  /// Número máximo de repetições, opcional (alternativa a [until]).
  final int? count;

  const RecurrenceRule({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
    this.weekdays,
    this.until,
    this.count,
  });

  bool get isRecurring => frequency != RecurrenceFrequency.none;

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    String? until,
    int? count,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      until: until ?? this.until,
      count: count ?? this.count,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'recurrence_frequency': frequency.name,
      'recurrence_interval': interval,
      'recurrence_weekdays': weekdays == null || weekdays!.isEmpty
          ? null
          : weekdays!.join(','),
      'recurrence_until': until,
      'recurrence_count': count,
    };
  }

  factory RecurrenceRule.fromMap(Map<String, Object?> map) {
    final weekdaysRaw = map['recurrence_weekdays'] as String?;
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values.firstWhere(
        (v) => v.name == (map['recurrence_frequency'] as String? ?? 'none'),
        orElse: () => RecurrenceFrequency.none,
      ),
      interval: map['recurrence_interval'] as int? ?? 1,
      weekdays: weekdaysRaw == null || weekdaysRaw.isEmpty
          ? null
          : weekdaysRaw.split(',').map(int.parse).toSet(),
      until: map['recurrence_until'] as String?,
      count: map['recurrence_count'] as int?,
    );
  }
}
