import 'models/category.dart';
import 'models/cycle_position.dart';

/// O resultado do motor de escala para uma data (seção 38): o que aquele
/// dia representa, e por quê.
class ScheduleDay {
  final String date;
  final Category category;

  /// Nome a exibir: o [CyclePosition.nameOverride] daquela posição, se
  /// houver, senão o nome da categoria.
  final String label;

  final String? startTime;
  final String? endTime;
  final bool crossesMidnight;

  /// Verdadeiro quando a data cai em uma regra fixa por dia da semana
  /// (seção 6), como domingo — e portanto NÃO passou pelo ciclo.
  final bool isFixedDay;

  /// Verdadeiro quando existe uma alteração manual (seção 39) para esta
  /// data, que prevalece sobre o cálculo automático.
  final bool isException;

  /// Só preenchido quando [isException] é verdadeiro: o que a escala
  /// automática diria para este dia, se a exceção não existisse.
  final Category? originalCategory;

  final CyclePosition? cyclePosition;

  /// Ex.: "Dia 1 de 2" — posição dentro do bloco de dias consecutivos da
  /// mesma categoria no ciclo (ver [ScheduleEngine.computeRunInfo]).
  final int? cycleDayNumber;
  final int? cycleDayCount;

  const ScheduleDay({
    required this.date,
    required this.category,
    required this.label,
    this.startTime,
    this.endTime,
    this.crossesMidnight = false,
    this.isFixedDay = false,
    this.isException = false,
    this.originalCategory,
    this.cyclePosition,
    this.cycleDayNumber,
    this.cycleDayCount,
  });

  bool get hasTime => startTime != null && endTime != null;
}
