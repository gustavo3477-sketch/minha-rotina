import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/providers.dart';
import '../../domain/schedule_day.dart';
import '../day_detail/day_detail_page.dart';
import 'current_month_provider.dart';
import 'widgets/calendar_day_cell.dart';
import 'widgets/calendar_legend.dart';

const _weekdayHeaders = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

/// Tela de calendário (Etapa 4, seção 9-10): cada quadrado usa a cor da
/// categoria daquele dia, ocupando área significativa (não só um ponto).
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);

    final gridStart = _gridStart(month);
    final gridEnd = _gridEnd(month);
    final range = (dutil.toIsoDate(gridStart), dutil.toIsoDate(gridEnd));

    final engineAsync = ref.watch(scheduleEngineProvider(range));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("MMMM 'de' yyyy", 'pt_BR').format(month)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(currentMonthProvider.notifier).state =
                startOfCurrentMonthUtc(),
            child: const Text('Hoje'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(currentMonthProvider.notifier).state =
                DateTime.utc(month.year, month.month - 1, 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(currentMonthProvider.notifier).state =
                DateTime.utc(month.year, month.month + 1, 1),
          ),
        ],
      ),
      body: engineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(message: '$error'),
        data: (engine) {
          List<ScheduleDay> days;
          try {
            days = engine.resolveRange(gridStart, gridEnd);
          } on StateError {
            // Nenhuma escala configurada ainda — a tela raiz normalmente
            // já encaminha para a configuração inicial antes de chegar
            // aqui; isto é só uma rede de segurança.
            days = const [];
          }
          final byDate = {for (final d in days) d.date: d};
          final columns = 7;
          final totalCells = dutil.daysBetweenUtc(gridStart, gridEnd) + 1;
          final rows = (totalCells / columns).ceil();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final h in _weekdayHeaders)
                        Expanded(
                          child: Center(
                            child: Text(
                              h,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows * columns,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemBuilder: (context, index) {
                      final date = dutil.addDaysUtc(gridStart, index);
                      final iso = dutil.toIsoDate(date);
                      return CalendarDayCell(
                        date: date,
                        day: byDate[iso],
                        inCurrentMonth:
                            date.month == month.month &&
                            date.year == month.year,
                        isToday: date == todayUtc,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayDetailPage(date: date),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  categoriesAsync.when(
                    data: (categories) =>
                        CalendarLegend(categories: categories),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _gridStart(DateTime month) {
    final firstOfMonth = DateTime.utc(month.year, month.month, 1);
    final leadingDays = firstOfMonth.weekday - 1; // grade começa na segunda
    return firstOfMonth.subtract(Duration(days: leadingDays));
  }

  DateTime _gridEnd(DateTime month) {
    final lastOfMonth = DateTime.utc(month.year, month.month + 1, 0);
    final trailingDays = (7 - lastOfMonth.weekday) % 7;
    return lastOfMonth.add(Duration(days: trailingDays));
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
          'Não foi possível calcular o calendário:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
