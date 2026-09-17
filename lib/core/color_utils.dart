import 'package:flutter/material.dart';

/// Converte uma cor em hex ("#RRGGBB" ou "#RGB") salva no banco para [Color].
Color colorFromHex(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  return Color(int.parse('FF$value', radix: 16));
}

/// Texto branco ou escuro sobre [background], pela luminância (seção 44:
/// não depender só da cor — o contraste também precisa ser adequado).
Color contrastingTextColor(Color background) {
  return background.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
}
