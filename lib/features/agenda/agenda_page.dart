import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_utils.dart' as dutil;
import '../../domain/models/category.dart';
import '../../domain/providers.dart';
import '../appointment_form/appointment_form_page.dart';
import '../day_detail/widgets/appointment_tile.dart';

/// Aba "Agenda" (Etapa 8, seção 15): lista as ocorrências de compromissos
/// dos próximos meses (já com recorrência expandida, Etapa 7), agrupadas
/// por data, com busca por título/descrição/local (seção 43) que não fica
/// limitada a essa janela — busca em todos os compromissos cadastrados.
class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  // Janela fixa em vez de "tudo" (seção 37); compromissos fora dela ainda
  // são encontráveis pela busca, que não é limitada por data.
  static const _windowDays = 180;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayUtc();
    final range = (
      dutil.toIsoDate(today),
      dutil.toIsoDate(dutil.addDaysUtc(today, _windowDays)),
    );
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoriesById = <String, Category>{
      for (final c in categoriesAsync.valueOrNull ?? []) c.id: c,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título, descrição ou local',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _AgendaList(range: range, categoriesById: categoriesById)
                : _SearchResults(query: _query, categoriesById: categoriesById),
          ),
        ],
      ),
    );
  }

  DateTime _todayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }
}

class _AgendaList extends ConsumerWidget {
  final DateRangeKey range;
  final Map<String, Category> categoriesById;

  const _AgendaList({required this.range, required this.categoriesById});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(agendaInRangeProvider(range));

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Não foi possível carregar a agenda:\n$error'),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('Nenhum compromisso nos próximos meses.'),
          );
        }

        final today = dutil.fromIsoDate(range.$1);
        final items = <Widget>[];
        DateTime? lastDate;
        for (final entry in entries) {
          final (date, appointment) = entry;
          if (lastDate == null || date != lastDate) {
            items.add(_DateHeader(date: date, today: today));
            lastDate = date;
          }
          items.add(
            AppointmentTile(
              appointment: appointment,
              category: categoriesById[appointment.categoryId],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentFormPage(
                    initialDate: date,
                    existing: appointment,
                  ),
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: items,
        );
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final Map<String, Category> categoriesById;

  const _SearchResults({required this.query, required this.categoriesById});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(agendaSearchProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Não foi possível buscar:\n$error'),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(child: Text('Nenhum resultado para "$query".'));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final appointment in results)
              AppointmentTile(
                appointment: appointment,
                category: categoriesById[appointment.categoryId],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentFormPage(
                      initialDate: dutil.fromIsoDate(appointment.date),
                      existing: appointment,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final DateTime today;

  const _DateHeader({required this.date, required this.today});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        _label(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _label() {
    final diff = dutil.daysBetweenUtc(today, date);
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Amanhã';
    return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
  }
}
