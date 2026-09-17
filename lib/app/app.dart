import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'bootstrap_placeholder_screen.dart';

/// Widget raiz do Minha Rotina.
///
/// Etapa 1: apenas o "casco" do app (tema claro/escuro + Material 3).
/// A navegação real (Hoje / Calendário / Agenda / Ajustes) chega na Etapa 4+.
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
      home: const BootstrapPlaceholderScreen(),
    );
  }
}
