import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/domain/models/recurrence_rule.dart';

void main() {
  test('toMap/fromMap preserva os dias da semana (seção 13)', () {
    const rule = RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 1,
      weekdays: {1, 3, 5},
    );

    final restored = RecurrenceRule.fromMap(rule.toMap());

    expect(restored.frequency, RecurrenceFrequency.weekly);
    expect(restored.weekdays, {1, 3, 5});
  });

  test(
    'sem weekdays, fromMap devolve null (repete no mesmo dia da âncora)',
    () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
      final restored = RecurrenceRule.fromMap(rule.toMap());
      expect(restored.weekdays, isNull);
    },
  );

  test('isRecurring é falso apenas para frequency none', () {
    expect(const RecurrenceRule().isRecurring, isFalse);
    expect(
      const RecurrenceRule(frequency: RecurrenceFrequency.daily).isRecurring,
      isTrue,
    );
  });

  test('mapa sem as chaves de recorrência assume "none" (compatível com fromMap direto do banco)', () {
    final restored = RecurrenceRule.fromMap(const {});
    expect(restored.frequency, RecurrenceFrequency.none);
    expect(restored.interval, 1);
  });
}
