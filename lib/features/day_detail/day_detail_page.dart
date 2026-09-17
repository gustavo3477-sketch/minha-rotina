import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/providers.dart';
import 'widgets/appointment_tile.dart';
import 'widgets/schedule_day_summary.dart';

/// Tela de detalhe do dia (Etapa 5, seção 10): substitui a prévia em bottom
/// sheet temporária do calendário por uma tela completa, com a escala do
/// dia e os compromissos daquela data.
class DayDetailPage extends ConsumerWidget {
  final DateTime date;

  const DayDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = dutil.toIsoDate(date);
    final range = (iso, iso);
    final engineAsync = ref.watch(scheduleEngineProvider(range));
    final appointmentsAsync = ref.watch(appointmentsForDateProvider(iso));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date)),
      ),
      body: engineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(message: '$error'),
        data: (engine) {
          final day = engine.resolveDay(date);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScheduleDaySummary(day: day),
              const SizedBox(height: 24),
              Text(
                'Compromissos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              appointmentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text('Erro ao carregar: $error'),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const Text('Nenhum compromisso neste dia.');
                  }
                  final categoriesById = {
                    for (final c in categoriesAsync.valueOrNull ?? []) c.id: c,
                  };
                  return Column(
                    children: [
                      for (final appointment in appointments)
                        AppointmentTile(
                          appointment: appointment,
                          category: categoriesById[appointment.categoryId],
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro de compromissos chega na Etapa 6.'),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Não foi possível calcular este dia:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
