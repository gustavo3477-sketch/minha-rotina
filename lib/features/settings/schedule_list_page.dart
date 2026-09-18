import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/models/cycle_position.dart';
import '../../domain/models/fixed_day_rule.dart';
import '../../domain/models/schedule_version.dart';
import '../../domain/providers.dart';
import 'schedule_editor_page.dart';

/// Lista as versões de escala (seção 40: trocar de escala sem afetar o
/// histórico), mais recente primeiro. Tocar edita aquela versão; o "+"
/// cria uma nova, em vigor a partir de uma data escolhida.
class ScheduleListPage extends ConsumerWidget {
  const ScheduleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(scheduleVersionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escala')),
      body: versionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
        data: (versions) {
          final sorted = [...versions]
            ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              for (final version in sorted)
                ListTile(
                  title: Text(version.name),
                  subtitle: Text(
                    'Em vigor a partir de ${version.effectiveFrom}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScheduleEditorPage(initial: version, isNew: false),
                    ),
                  ),
                ),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma escala configurada ainda.'),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewVersion(context, ref, versionsAsync.value),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNewVersion(
    BuildContext context,
    WidgetRef ref,
    List<ScheduleVersion>? versions,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime.utc(today.year - 1),
      lastDate: DateTime.utc(today.year + 5),
      helpText: 'A partir de quando esta escala passa a valer?',
    );
    if (picked == null) return;

    final effectiveFrom = dutil.toIsoDate(
      DateTime.utc(picked.year, picked.month, picked.day),
    );
    final mostRecent = (versions == null || versions.isEmpty)
        ? null
        : ([
            ...versions,
          ]..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom))).first;

    final newId = 'schedule-${const Uuid().v4()}';
    final template = mostRecent == null
        ? ScheduleVersion(
            id: newId,
            name: 'Nova escala',
            effectiveFrom: effectiveFrom,
            referenceDate: effectiveFrom,
            referencePositionIndex: 0,
            cyclePositions: const [],
            fixedDayRules: const [],
          )
        : ScheduleVersion(
            id: newId,
            name: mostRecent.name,
            effectiveFrom: effectiveFrom,
            referenceDate: effectiveFrom,
            referencePositionIndex: mostRecent.referencePositionIndex,
            cyclePositions: [
              for (final p in mostRecent.sortedCyclePositions)
                CyclePosition(
                  id: const Uuid().v4(),
                  scheduleVersionId: newId,
                  order: p.order,
                  categoryId: p.categoryId,
                  nameOverride: p.nameOverride,
                  startTime: p.startTime,
                  endTime: p.endTime,
                ),
            ],
            fixedDayRules: [
              for (final r in mostRecent.fixedDayRules)
                FixedDayRule(
                  id: const Uuid().v4(),
                  scheduleVersionId: newId,
                  weekday: r.weekday,
                  enabled: r.enabled,
                  categoryId: r.categoryId,
                ),
            ],
          );

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleEditorPage(initial: template, isNew: true),
      ),
    );
  }
}
