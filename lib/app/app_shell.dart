import 'package:flutter/material.dart';

import '../features/calendar/calendar_page.dart';
import '../features/home/home_page.dart';

/// Navegação inferior (seção 17): Hoje | Calendário | + | Agenda | Ajustes.
///
/// "Hoje" e "Calendário" estão implementadas (Etapas 4 e 5). As outras
/// abas mostram um aviso honesto em vez de fingir uma tela pronta —
/// chegam nas etapas 8 e 10.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0; // começa em "Hoje" — a tela que a pessoa quer ver primeiro

  static const _pages = [
    HomePage(),
    CalendarPage(),
    _ComingSoonPage(title: 'Agenda', etapa: 8),
    _ComingSoonPage(title: 'Ajustes', etapa: 10),
  ];

  void _onAddPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro de compromissos chega na Etapa 6.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // _pages não inclui o botão "+" central — os índices de navegação
    // (0,1,2,3) mapeiam para (Hoje,Calendário,Agenda,Ajustes); o botão "+"
    // não é uma página, é uma ação.
    return Scaffold(
      body: _pages[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: Icons.today,
              label: 'Hoje',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavButton(
              icon: Icons.calendar_month,
              label: 'Calendário',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            const SizedBox(width: 48), // espaço reservado ao "+" central
            _NavButton(
              icon: Icons.list_alt,
              label: 'Agenda',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavButton(
              icon: Icons.settings,
              label: 'Ajustes',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final int etapa;

  const _ComingSoonPage({required this.title, required this.etapa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title chega na Etapa $etapa.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
