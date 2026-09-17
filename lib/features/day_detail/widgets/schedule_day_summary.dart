import 'package:flutter/material.dart';

import '../../../core/color_utils.dart';
import '../../../domain/schedule_day.dart';

/// Resumo visual do que um dia representa na escala (seção 38): categoria,
/// horário (se houver) e posição no ciclo ("Dia X de Y"). Reaproveitado pela
/// tela Hoje e pelo detalhe do dia para não duplicar este bloco.
class ScheduleDaySummary extends StatelessWidget {
  final ScheduleDay day;

  const ScheduleDaySummary({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFromHex(day.category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(day.label, style: theme.textTheme.titleLarge)),
          ],
        ),
        if (day.hasTime)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${day.startTime} → ${day.endTime}',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        if (day.cycleDayNumber != null && day.cycleDayCount != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Dia ${day.cycleDayNumber} de ${day.cycleDayCount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (day.isFixedDay)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Dia fixo — fora da contagem do ciclo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (day.isException)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Marcação manual (escala automática: '
              '${day.originalCategory?.name})',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
