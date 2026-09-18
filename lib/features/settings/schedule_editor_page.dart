import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers.dart';
import '../../domain/date_utils.dart' as dutil;
import '../../domain/models/category.dart';
import '../../domain/models/cycle_position.dart';
import '../../domain/models/fixed_day_rule.dart';
import '../../domain/models/schedule_version.dart';
import '../../domain/providers.dart';

const _weekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Editor completo do ciclo de uma escala (seção 5/6/7/40): posições do
/// ciclo (categoria, nome, horário), dias fixos por dia da semana, e a
/// data de referência do ciclo.
///
/// [isNew] verdadeiro grava com [ScheduleRepository.insertVersion] (uma
/// versão nova, seção 40 — trocar de escala sem afetar o histórico);
/// falso grava com [updateVersion] (edita a versão em vigor). Em ambos os
/// casos, [initial] já vem com id e effectiveFrom definidos por quem abriu
/// esta tela — não são editáveis aqui.
class ScheduleEditorPage extends ConsumerStatefulWidget {
  final ScheduleVersion initial;
  final bool isNew;

  const ScheduleEditorPage({
    super.key,
    required this.initial,
    required this.isNew,
  });

  @override
  ConsumerState<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ScheduleEditorPageState extends ConsumerState<ScheduleEditorPage> {
  late final TextEditingController _nameController;
  late DateTime _referenceDate;
  late int _referencePositionIndex;
  late List<CyclePosition> _positions;
  late Map<int, String?> _fixedDayRules;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial.name);
    _referenceDate = dutil.fromIsoDate(initial.referenceDate);
    _referencePositionIndex = initial.referencePositionIndex;
    _positions = [...initial.sortedCyclePositions];
    _fixedDayRules = {
      for (var w = 1; w <= 7; w++) w: null,
      for (final rule in initial.fixedDayRules)
        if (rule.enabled) rule.weekday: rule.categoryId,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Nova escala' : 'Editar escala'),
        actions: [TextButton(onPressed: _save, child: const Text('Salvar'))],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
        data: (categories) {
          final scheduleCategories = categories
              .where((c) => c.kind == CategoryKind.schedule)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da escala'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Em vigor a partir de'),
                subtitle: Text(widget.initial.effectiveFrom),
              ),
              const Divider(height: 32),
              Text(
                'Ciclo (seção 5)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _positions.length; i++)
                _PositionCard(
                  key: ValueKey(_positions[i].id),
                  position: _positions[i],
                  categories: scheduleCategories,
                  canRemove: _positions.length > 1,
                  onChanged: (updated) =>
                      setState(() => _positions[i] = updated),
                  onRemove: () => setState(() {
                    _positions.removeAt(i);
                    if (_referencePositionIndex >= _positions.length) {
                      _referencePositionIndex = _positions.length - 1;
                    }
                  }),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Adicionar posição do ciclo'),
                onTap: scheduleCategories.isEmpty
                    ? null
                    : () => setState(() {
                        _positions.add(
                          CyclePosition(
                            id: const Uuid().v4(),
                            scheduleVersionId: widget.initial.id,
                            order: _positions.length + 1,
                            categoryId: scheduleCategories.first.id,
                          ),
                        );
                      }),
              ),
              const Divider(height: 32),
              Text(
                'Data de referência (seção 38)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data conhecida'),
                subtitle: Text(dutil.toIsoDate(_referenceDate)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickReferenceDate,
              ),
              if (_positions.isEmpty)
                const Text('Adicione ao menos uma posição do ciclo primeiro.')
              else
                DropdownButtonFormField<int>(
                  // Recria o widget (reaplicando initialValue) quando o
                  // índice muda por remoção de posição, não só por
                  // interação direta.
                  key: ValueKey(_referencePositionIndex),
                  initialValue: _referencePositionIndex.clamp(
                    0,
                    _positions.length - 1,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nessa data, qual posição do ciclo era essa?',
                  ),
                  items: [
                    for (var i = 0; i < _positions.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          'Posição ${i + 1}: '
                          '${_categoryName(scheduleCategories, _positions[i].categoryId)}',
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _referencePositionIndex = value ?? 0),
                ),
              const Divider(height: 32),
              Text(
                'Dias fixos da semana (seção 6)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Um dia fixo sempre usa a mesma categoria e não entra na '
                'contagem do ciclo — ex.: domingo sempre de folga.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (var weekday = 1; weekday <= 7; weekday++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(_weekdayNames[weekday - 1]),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _fixedDayRules[weekday],
                          decoration: const InputDecoration(isDense: true),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Segue o ciclo'),
                            ),
                            for (final category in scheduleCategories)
                              DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _fixedDayRules[weekday] = value),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _categoryName(List<Category> categories, String id) {
    return categories
        .firstWhere(
          (c) => c.id == id,
          orElse: () => Category(
            id: id,
            kind: CategoryKind.schedule,
            name: '(categoria removida)',
            color: '#6B7280',
          ),
        )
        .name;
  }

  Future<void> _pickReferenceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referenceDate,
      firstDate: DateTime.utc(_referenceDate.year - 5),
      lastDate: DateTime.utc(_referenceDate.year + 5),
    );
    if (picked != null) {
      setState(
        () => _referenceDate = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
        ),
      );
    }
  }

  Future<void> _save() async {
    final normalizedPositions = [
      for (var i = 0; i < _positions.length; i++)
        _positions[i].copyWith(order: i + 1),
    ];
    final rules = [
      for (final entry in _fixedDayRules.entries)
        if (entry.value != null)
          FixedDayRule(
            id: const Uuid().v4(),
            scheduleVersionId: widget.initial.id,
            weekday: entry.key,
            enabled: true,
            categoryId: entry.value!,
          ),
    ];

    final version = widget.initial.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.initial.name
          : _nameController.text.trim(),
      referenceDate: dutil.toIsoDate(_referenceDate),
      referencePositionIndex: _referencePositionIndex,
      cyclePositions: normalizedPositions,
      fixedDayRules: rules,
    );

    final repo = ref.read(scheduleRepositoryProvider);
    if (widget.isNew) {
      await repo.insertVersion(version);
    } else {
      await repo.updateVersion(version);
    }
    ref.invalidate(scheduleVersionsProvider);
    ref.invalidate(hasScheduleConfiguredProvider);
    if (mounted) Navigator.pop(context);
  }
}

class _PositionCard extends StatelessWidget {
  final CyclePosition position;
  final List<Category> categories;
  final bool canRemove;
  final ValueChanged<CyclePosition> onChanged;
  final VoidCallback onRemove;

  const _PositionCard({
    super.key,
    required this.position,
    required this.categories,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: position.categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      isDense: true,
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => value == null
                        ? null
                        : onChanged(position.copyWith(categoryId: value)),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: position.nameOverride ?? '',
              decoration: const InputDecoration(
                labelText: 'Nome nesta posição (opcional)',
                isDense: true,
              ),
              // copyWith não consegue limpar um campo nulo (cai de volta no
              // valor antigo) — por isso reconstrói o objeto direto aqui,
              // para apagar o texto realmente remover o nameOverride.
              onChanged: (value) => onChanged(
                CyclePosition(
                  id: position.id,
                  scheduleVersionId: position.scheduleVersionId,
                  order: position.order,
                  categoryId: position.categoryId,
                  nameOverride: value.trim().isEmpty ? null : value.trim(),
                  startTime: position.startTime,
                  endTime: position.endTime,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Início'),
                    subtitle: Text(position.startTime ?? 'Não definido'),
                    onTap: () => _pickTime(context, isStart: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Fim'),
                    subtitle: Text(position.endTime ?? 'Não definido'),
                    onTap: () => _pickTime(context, isStart: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final current = isStart ? position.startTime : position.endTime;
    final initial = current != null
        ? TimeOfDay(
            hour: int.parse(current.split(':')[0]),
            minute: int.parse(current.split(':')[1]),
          )
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    onChanged(
      isStart
          ? position.copyWith(startTime: formatted)
          : position.copyWith(endTime: formatted),
    );
  }
}
