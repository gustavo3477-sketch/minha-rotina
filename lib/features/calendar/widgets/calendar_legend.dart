import 'package:flutter/material.dart';

import '../../../core/color_utils.dart';
import '../../../domain/models/category.dart';

/// Legenda do calendário — construída a partir das categorias reais
/// (nunca cores fixas no código, seção 7): se o usuário renomear ou
/// recolorir uma categoria, a legenda acompanha automaticamente.
class CalendarLegend extends StatelessWidget {
  final List<Category> categories;

  const CalendarLegend({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final scheduleCategories =
        categories.where((c) => c.kind == CategoryKind.schedule).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final category in scheduleCategories)
          _LegendItem(
            color: colorFromHex(category.color),
            label: category.name,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
