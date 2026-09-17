import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/models/category.dart';
import '../../domain/providers.dart';
import '../appointment_form/appointment_form_page.dart';
import '../day_detail/day_detail_page.dart';
import '../day_detail/widgets/appointment_tile.dart';
import '../day_detail/widgets/schedule_day_summary.dart';

/// Aba "Hoje" (Etapa 5, seção 10): o que o dia de hoje representa, quando é
/// a próxima folga e os compromissos de hoje — o que a pessoa quer ver
/// primeiro ao abrir o app.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _nextRestSearchDays = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _todayUtc();
    final todayIso = dutil.toIsoDate(today);
    final range = (
      todayIso,
      dutil.toIsoDate(dutil.addDaysUtc(today, _nextRestSearchDays)),
    );

    final engineAsync = ref.watch(scheduleEngineProvider(range));
    final appointmentsAsync = ref.watch(appointmentsForDateProvider(todayIso));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(today)),
      ),
      body: engineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(message: '$error'),
        data: (engine) {
          final day = engine.resolveDay(today);
          final nextRest = engine.findNextByClassification(
            dutil.addDaysUtc(today, 1),
            ScheduleClassification.rest,
            maxDays: _nextRestSearchDays,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ScheduleDaySummary(day: day),
                ),
              ),
              if (nextRest != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ListTile(
                    leading: const Icon(Icons.beach_access_outlined),
                    title: const Text('Próxima folga'),
                    subtitle: Text(
                      DateFormat(
                        "EEEE, d 'de' MMMM",
                        'pt_BR',
                      ).format(dutil.fromIsoDate(nextRest.date)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compromissos de hoje',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayDetailPage(date: today),
                      ),
                    ),
                    child: const Text('Ver detalhes do dia'),
                  ),
                ],
              ),
              appointmentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text('Erro ao carregar: $error'),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhum compromisso para hoje.'),
                    );
                  }
                  final categoriesById = <String, Category>{
                    for (final c in categoriesAsync.valueOrNull ?? []) c.id: c,
                  };
                  return Column(
                    children: [
                      for (final appointment in appointments)
                        AppointmentTile(
                          appointment: appointment,
                          category: categoriesById[appointment.categoryId],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentFormPage(
                                initialDate: today,
                                existing: appointment,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _todayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
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
          'Não foi possível calcular o dia de hoje:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
