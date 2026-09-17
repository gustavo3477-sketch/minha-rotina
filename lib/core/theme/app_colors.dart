import 'package:flutter/material.dart';

/// Paleta de marca do Minha Rotina.
///
/// As cores de categorias (Trabalho, Folga, Extra...) NÃO ficam fixas aqui —
/// elas são configuráveis pelo usuário e vivem no banco de dados (categorias).
/// Esta classe contém apenas as cores estruturais do app (marca, superfícies).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);

  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
}
