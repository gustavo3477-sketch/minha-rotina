import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers.dart';
import '../../domain/date_utils.dart' as dutil;
import '../../domain/default_categories.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/category.dart';
import '../../domain/providers.dart';

const _reminderOptions = <int?, String>{
  null: 'Sem lembrete',
  0: 'Na hora',
  15: '15 minutos antes',
  30: '30 minutos antes',
  60: '1 hora antes',
  1440: '1 dia antes',
};

/// Tela de criar/editar compromisso (Etapa 6, seção 11/12) — [existing] nulo
/// significa criação; caso contrário, edita aquele compromisso (e permite
/// excluí-lo). "Trabalho extra" (seção 14) é o mesmo formulário com um
/// campo de valor extra, não uma tela separada.
///
/// Recorrência (seção 13) ainda não aparece aqui — chega na Etapa 7. Todo
/// compromisso criado agora é uma ocorrência única.
class AppointmentFormPage extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Appointment? existing;

  const AppointmentFormPage({
    super.key,
    required this.initialDate,
    this.existing,
  });

  @override
  ConsumerState<AppointmentFormPage> createState() =>
      _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;

  late DateTime _date;
  late bool _allDay;
  String? _startTime;
  String? _endTime;
  String? _categoryId;
  int? _reminderMinutesBefore;
  late AppointmentKind _kind;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _valueController = TextEditingController(
      text: existing?.value != null ? existing!.value!.toStringAsFixed(2) : '',
    );
    _date = existing != null
        ? dutil.fromIsoDate(existing.date)
        : widget.initialDate;
    _allDay = existing?.allDay ?? true;
    _startTime = existing?.startTime;
    _endTime = existing?.endTime;
    _categoryId = existing?.categoryId ?? kGeneralAppointmentCategoryId;
    _reminderMinutesBefore = existing?.reminderMinutesBefore;
    _kind = existing?.kind ?? AppointmentKind.normal;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar compromisso' : 'Novo compromisso'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(onPressed: _save, child: const Text('Salvar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Este é um trabalho extra'),
              subtitle: const Text('Seção 14 — reaproveita este formulário'),
              value: _kind == AppointmentKind.extraShift,
              onChanged: (value) => setState(
                () => _kind = value
                    ? AppointmentKind.extraShift
                    : AppointmentKind.normal,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe um título.'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(dutil.toIsoDate(_date)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dia todo'),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
            ),
            if (!_allDay) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Início'),
                subtitle: Text(_startTime ?? 'Não definido'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fim'),
                subtitle: Text(_endTime ?? 'Não definido'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickTime(isStart: false),
              ),
            ],
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) {
                final tags = categories
                    .where((c) => c.kind == CategoryKind.appointment)
                    .toList();
                return DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sem categoria'),
                    ),
                    for (final tag in tags)
                      DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Local (opcional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _reminderMinutesBefore,
              decoration: const InputDecoration(labelText: 'Lembrete'),
              items: [
                for (final entry in _reminderOptions.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) =>
                  setState(() => _reminderMinutesBefore = value),
            ),
            if (_kind == AppointmentKind.extraShift) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Valor (opcional)',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.utc(_date.year - 5),
      lastDate: DateTime.utc(_date.year + 5),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
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
    if (!_allDay && _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o horário de início.')),
      );
      return;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rawValue = _valueController.text.trim().replaceAll(',', '.');
    final appointment = Appointment(
      id: widget.existing?.id ?? const Uuid().v4(),
      kind: _kind,
      title: _titleController.text.trim(),
      date: dutil.toIsoDate(_date),
      allDay: _allDay,
      startTime: _allDay ? null : _startTime,
      endTime: _allDay ? null : _endTime,
      categoryId: _categoryId,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reminderMinutesBefore: _reminderMinutesBefore,
      value: _kind == AppointmentKind.extraShift && rawValue.isNotEmpty
          ? double.tryParse(rawValue)
          : null,
      createdAt: widget.existing?.createdAt ?? nowIso,
      updatedAt: nowIso,
    );

    final repo = ref.read(appointmentRepositoryProvider);
    if (_isEditing) {
      await repo.update(appointment);
    } else {
      await repo.insert(appointment);
    }
    ref.invalidate(appointmentsForDateProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compromisso?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(appointmentRepositoryProvider).delete(widget.existing!.id);
    ref.invalidate(appointmentsForDateProvider);
    if (mounted) Navigator.pop(context);
  }
}
