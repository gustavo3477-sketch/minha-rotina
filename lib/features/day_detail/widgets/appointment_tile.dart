import 'package:flutter/material.dart';

import '../../../core/color_utils.dart';
import '../../../domain/models/appointment.dart';
import '../../../domain/models/category.dart';

/// Uma linha de compromisso (seção 11/12) na lista do dia. Tocar abre a
/// edição (Etapa 6) daquele compromisso.
class AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final Category? category;
  final VoidCallback? onTap;

  const AppointmentTile({
    super.key,
    required this.appointment,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = category != null ? colorFromHex(category!.color) : null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: tagColor ?? theme.colorScheme.surfaceContainerHigh,
        child: Icon(
          appointment.kind == AppointmentKind.extraShift
              ? Icons.work_outline
              : Icons.event_outlined,
          color: tagColor != null
              ? contrastingTextColor(tagColor)
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(appointment.title)),
          if (appointment.recurrence.isRecurring)
            Icon(
              Icons.repeat,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
      subtitle: Text(_subtitle()),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (appointment.allDay) {
      parts.add('Dia todo');
    } else if (appointment.startTime != null) {
      parts.add(
        appointment.endTime != null
            ? '${appointment.startTime} → ${appointment.endTime}'
            : appointment.startTime!,
      );
    }
    if (appointment.location != null && appointment.location!.isNotEmpty) {
      parts.add(appointment.location!);
    }
    if (appointment.kind == AppointmentKind.extraShift &&
        appointment.value != null) {
      parts.add('R\$ ${appointment.value!.toStringAsFixed(2)}');
    }
    return parts.isEmpty ? 'Sem horário definido' : parts.join(' · ');
  }
}
