import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/category_colors.dart';
import '../../core/category_icons.dart';
import '../../core/color_utils.dart';
import '../../data/providers.dart';
import '../../domain/models/category.dart';
import '../../domain/providers.dart';

const _classificationLabels = <ScheduleClassification, String>{
  ScheduleClassification.work: 'Trabalho (conta como dia de serviço)',
  ScheduleClassification.rest: 'Folga (conta como dia de descanso)',
  ScheduleClassification.manual: 'Outro (não entra em "próxima folga")',
};

/// Cria ou edita uma categoria (seção 7). [kind] define o tipo quando
/// [existing] é nulo (criação); ao editar, o tipo já vem de [existing] e
/// não muda mais — trocar o tipo de uma categoria já em uso (numa posição
/// do ciclo, ou como tag de um compromisso) não faz sentido.
///
/// [ScheduleClassification] (seção "trabalho"/"folga"/"manual") também só é
/// escolhida na criação: o motor de escala e a busca por "próxima folga"
/// dependem dela permanecer estável depois que a categoria já está em uso.
class CategoryFormPage extends ConsumerStatefulWidget {
  final CategoryKind kind;
  final Category? existing;

  const CategoryFormPage({super.key, required this.kind, this.existing});

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _color;
  late String? _icon;
  late ScheduleClassification _classification;
  String? _startTime;
  String? _endTime;

  bool get _isEditing => widget.existing != null;
  bool get _isScheduleKind => widget.kind == CategoryKind.schedule;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _color = existing?.color ?? categoryColorPalette.first;
    _icon = existing?.icon;
    _classification = existing?.classification ?? ScheduleClassification.work;
    _startTime = existing?.defaultStartTime;
    _endTime = existing?.defaultEndTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar categoria' : 'Nova categoria'),
        actions: [TextButton(onPressed: _save, child: const Text('Salvar'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe um nome.'
                  : null,
            ),
            const SizedBox(height: 20),
            Text('Cor', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final hex in categoryColorPalette)
                  _ColorSwatch(
                    hex: hex,
                    selected: hex == _color,
                    onTap: () => setState(() => _color = hex),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in categoryIconsByName.entries)
                  _IconChoice(
                    icon: entry.value,
                    selected: entry.key == _icon,
                    onTap: () => setState(() => _icon = entry.key),
                  ),
              ],
            ),
            if (_isScheduleKind) ...[
              const SizedBox(height: 20),
              if (!_isEditing) ...[
                Text(
                  'O que esta categoria representa',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                RadioGroup<ScheduleClassification>(
                  groupValue: _classification,
                  onChanged: (value) =>
                      setState(() => _classification = value!),
                  child: Column(
                    children: [
                      for (final entry in _classificationLabels.entries)
                        RadioListTile<ScheduleClassification>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(entry.value),
                          value: entry.key,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Horário padrão (opcional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Início'),
                      subtitle: Text(_startTime ?? 'Não definido'),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fim'),
                      subtitle: Text(_endTime ?? 'Não definido'),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
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
    setState(() {
      if (isStart) {
        _startTime = formatted;
      } else {
        _endTime = formatted;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;
    final category = Category(
      id: existing?.id ?? const Uuid().v4(),
      kind: widget.kind,
      name: _nameController.text.trim(),
      color: _color,
      icon: _icon,
      defaultStartTime: _isScheduleKind ? _startTime : null,
      defaultEndTime: _isScheduleKind ? _endTime : null,
      classification: _isScheduleKind
          ? (existing?.classification ?? _classification)
          : null,
      isCore: existing?.isCore ?? false,
      sortOrder: existing?.sortOrder ?? 0,
    );

    final repo = ref.read(categoryRepositoryProvider);
    if (_isEditing) {
      await repo.update(category);
    } else {
      await repo.insert(category);
    }
    ref.invalidate(categoriesProvider);
    if (mounted) Navigator.pop(context);
  }
}

class _ColorSwatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: selected
            ? Icon(Icons.check, color: contrastingTextColor(color))
            : null,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: selected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
