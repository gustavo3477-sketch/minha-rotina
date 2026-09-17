/// Utilidades de data usadas pelo motor de escala.
///
/// Tudo aqui usa [DateTime.utc] deliberadamente — mesmo representando datas
/// "sem hora" (calendário, não instante). Isso evita o problema clássico de
/// horário de verão: `DateTime` local pode ter dias com 23h ou 25h em uma
/// mudança de DST, o que corrompe contas como `b.difference(a).inDays`.
/// Em UTC isso nunca acontece.
library;

String toIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime fromIsoDate(String iso) {
  final parts = iso.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime addDaysUtc(DateTime date, int days) {
  return date.add(Duration(days: days));
}

/// Diferença exata em dias entre duas datas UTC "sem hora".
int daysBetweenUtc(DateTime a, DateTime b) {
  return b.difference(a).inDays;
}

int mod(int n, int m) => ((n % m) + m) % m;
