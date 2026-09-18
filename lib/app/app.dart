import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/providers.dart';
import '../domain/providers.dart';
import '../features/setup/quick_schedule_setup_page.dart';
import 'app_shell.dart';

/// Widget raiz do Minha Rotina.
///
/// Decide entre: carregando → configuração inicial (sem escala ainda) →
/// shell principal (Hoje/Calendário/Agenda/Ajustes).
class MinhaRotinaApp extends StatelessWidget {
  const MinhaRotinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Rotina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);

    return dbAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(message: '$error'),
      data: (_) {
        final hasScheduleAsync = ref.watch(hasScheduleConfiguredProvider);
        return hasScheduleAsync.when(
          loading: () => const _LoadingScreen(),
          error: (error, stack) => _ErrorScreen(message: '$error'),
          data: (hasSchedule) =>
              hasSchedule ? const AppShell() : const QuickScheduleSetupPage(),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends ConsumerWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Não foi possível iniciar o Minha Rotina:\n$message'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(databaseProvider);
                  ref.invalidate(hasScheduleConfiguredProvider);
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
