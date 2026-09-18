import 'package:flutter/material.dart';

import 'category_list_page.dart';
import 'schedule_list_page.dart';

/// Aba "Ajustes" (Etapa 10, seção 41): ponto de entrada para gerenciar
/// categorias e a escala. Backup/restauração chega na Etapa 11.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Categorias'),
            subtitle: const Text('Nomes, cores, ícones e horários padrão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryListPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Escala'),
            subtitle: const Text('Ciclo, dias fixos e histórico de escalas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleListPage()),
            ),
          ),
        ],
      ),
    );
  }
}
