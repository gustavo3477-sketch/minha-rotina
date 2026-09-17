import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../domain/date_utils.dart';
import '../../domain/default_schedule.dart';
import '../../domain/providers.dart';

/// Configuração inicial mínima — o suficiente para o motor de escala ter
/// uma primeira versão para calcular (seção 41 pede um onboarding mais
/// completo, com escolha de modelo de escala e regras especiais; isso é
/// enriquecido na Etapa 10, junto das telas de configuração).
class QuickScheduleSetupPage extends ConsumerStatefulWidget {
  const QuickScheduleSetupPage({super.key});

  @override
  ConsumerState<QuickScheduleSetupPage> createState() =>
      _QuickScheduleSetupPageState();
}

class _QuickScheduleSetupPageState
    extends ConsumerState<QuickScheduleSetupPage> {
  DateTime _referenceDate = DateTime.now();
  TimeOfDay _workStart = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 1, minute: 0);
  bool _saving = false;

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referenceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _referenceDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _workStart : _workEnd,
    );
    if (picked != null) {
      setState(() => isStart ? _workStart = picked : _workEnd = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final referenceIso = toIsoDate(
      DateTime.utc(
        _referenceDate.year,
        _referenceDate.month,
        _referenceDate.day,
      ),
    );
    final version = buildDefault2x2Schedule(
      id: 'schedule-${DateTime.now().microsecondsSinceEpoch}',
      referenceDate: referenceIso,
      workStart: _formatTime(_workStart),
      workEnd: _formatTime(_workEnd),
    );

    await ref.read(scheduleRepositoryProvider).insertVersion(version);
    ref.invalidate(scheduleVersionsProvider);
    ref.invalidate(hasScheduleConfiguredProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar minha escala')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como é sua escala?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Para começar, usamos o modelo 2 dias de trabalho / 2 dias de '
                'folga, com domingo sempre como folga fixa. Você pode criar '
                'escalas totalmente personalizadas depois, em Configurações.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Qual o primeiro dia conhecido dessa sequência (1º dia de trabalho)?',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  DateFormat(
                    "d 'de' MMMM 'de' yyyy",
                    'pt_BR',
                  ).format(_referenceDate),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Qual o horário de trabalho?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text('Início: ${_formatTime(_workStart)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text('Fim: ${_formatTime(_workEnd)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('MINHA ESCALA ESTÁ CORRETA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
