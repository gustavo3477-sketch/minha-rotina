import 'package:flutter/material.dart';

import '../../../core/color_utils.dart';
import '../../../domain/schedule_day.dart';

/// Um quadrado do calendário (seção 9): a cor da categoria preenche uma
/// área significativa do quadrado — não é só um pontinho — e o texto
/// (número do dia + nome curto da categoria) garante que a informação não
/// dependa só da cor (seção 44, acessibilidade).
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final ScheduleDay? day;
  final bool inCurrentMonth;
  final bool isToday;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.day,
    required this.inCurrentMonth,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = day;

    Color background = theme.colorScheme.surfaceContainerHigh;
    Color foreground = theme.colorScheme.onSurfaceVariant;
    if (resolved != null && inCurrentMonth) {
      background = colorFromHex(resolved.category.color);
      foreground = contrastingTextColor(background);
    }

    final opacity = inCurrentMonth ? 1.0 : 0.35;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 2.5)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (resolved != null && inCurrentMonth)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _shortLabel(resolved),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (resolved?.isException == true)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.edit,
                    size: 9,
                    color: foreground.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortLabel(ScheduleDay day) {
    final label = day.label.toUpperCase();
    return label.length <= 6 ? label : label.substring(0, 6);
  }
}
