import 'package:flutter_riverpod/flutter_riverpod.dart';

DateTime startOfCurrentMonthUtc() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, 1);
}

/// Mês (dia 1, meia-noite UTC) atualmente exibido no calendário.
final currentMonthProvider = StateProvider<DateTime>(
  (ref) => startOfCurrentMonthUtc(),
);
