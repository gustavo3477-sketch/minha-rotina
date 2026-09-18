import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'date_utils.dart' as dutil;
import 'models/appointment.dart';
import 'models/category.dart';
import 'models/schedule_exception.dart';
import 'models/schedule_version.dart';
import 'recurrence_engine.dart';
import 'schedule_engine.dart';

/// Todas as categorias (poucas dezenas no máximo — carregar tudo de uma vez
/// é aceitável; quem tem volume que justifica consulta por intervalo é
/// compromissos, seção 37).
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

/// Todas as versões de escala (normalmente poucas — uma por período de
/// vigência, seção 40).
final scheduleVersionsProvider = FutureProvider<List<ScheduleVersion>>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getAllVersions();
});

final hasScheduleConfiguredProvider = FutureProvider<bool>((ref) async {
  final versions = await ref.watch(scheduleVersionsProvider.future);
  return versions.isNotEmpty;
});

/// Chave de intervalo de datas (ISO) para providers `family` — records têm
/// igualdade por valor "de fábrica", perfeitos para isso.
typedef DateRangeKey = (String startIso, String endIso);

/// Exceções manuais só do intervalo visível (seção 37: nunca carregar tudo).
final scheduleExceptionsInRangeProvider =
    FutureProvider.family<List<ScheduleException>, DateRangeKey>((ref, range) {
      final repo = ref.watch(scheduleRepositoryProvider);
      return repo.getExceptionsInRange(range.$1, range.$2);
    });

/// O motor de escala (Etapa 3), já carregado com os dados necessários para
/// resolver qualquer data dentro de [range].
final scheduleEngineProvider =
    FutureProvider.family<ScheduleEngine, DateRangeKey>((ref, range) async {
      final categories = await ref.watch(categoriesProvider.future);
      final versions = await ref.watch(scheduleVersionsProvider.future);
      final exceptions = await ref.watch(
        scheduleExceptionsInRangeProvider(range).future,
      );
      return ScheduleEngine(
        versions: versions,
        categories: categories,
        exceptions: exceptions,
      );
    });

/// Compromissos de uma única data (seção 11: um dia pode ter vários),
/// já considerando recorrência (seção 13, Etapa 7): [AppointmentRepository.getForDate]
/// traz a ocorrência-âncora de tudo que PODE cair nesta data (inclusive
/// recorrentes ancorados antes dela); aqui filtramos para o que realmente
/// ocorre nesta data específica.
final appointmentsForDateProvider =
    FutureProvider.family<List<Appointment>, String>((ref, isoDate) async {
      final repo = ref.watch(appointmentRepositoryProvider);
      final candidates = await repo.getForDate(isoDate);
      final date = dutil.fromIsoDate(isoDate);
      return candidates
          .where((a) => expandOccurrences(a, date, date).isNotEmpty)
          .toList();
    });
