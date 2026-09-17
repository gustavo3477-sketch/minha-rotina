import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tela temporária da Etapa 1, apenas para confirmar que o projeto compila,
/// roda e que o tema está aplicado corretamente.
///
/// Será substituída pela navegação real (Hoje / Calendário / Agenda / Ajustes)
/// na Etapa 4 em diante.
class BootstrapPlaceholderScreen extends StatelessWidget {
  const BootstrapPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Minha Rotina',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  today,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Etapa 1 concluída: ambiente, projeto e arquitetura prontos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
