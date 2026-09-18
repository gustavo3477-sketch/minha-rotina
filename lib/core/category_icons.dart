import 'package:flutter/material.dart';

/// Ícones disponíveis para categorias (seção 7), por nome estável — o nome
/// é o que fica salvo em [Category.icon], nunca o [IconData] em si, para
/// não depender de uma versão exata do Flutter para continuar decodificável.
const categoryIconsByName = <String, IconData>{
  'briefcase': Icons.work_outline,
  'leaf': Icons.eco_outlined,
  'zap': Icons.bolt_outlined,
  'star': Icons.star_outline,
  'map-pin': Icons.location_on_outlined,
  'heart': Icons.favorite_outline,
  'medical': Icons.local_hospital_outlined,
  'gym': Icons.fitness_center_outlined,
  'book': Icons.menu_book_outlined,
  'home': Icons.home_outlined,
  'car': Icons.directions_car_outlined,
  'money': Icons.attach_money_outlined,
  'moon': Icons.nightlight_outlined,
  'sun': Icons.wb_sunny_outlined,
};

IconData iconForName(String? name) =>
    categoryIconsByName[name] ?? Icons.label_outline;
