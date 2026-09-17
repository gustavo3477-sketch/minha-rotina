import 'package:sqflite/sqflite.dart';

/// Configurações simples do app (seção 28/42) guardadas como chave-valor —
/// evita criar uma tabela rígida para cada preferência isolada (nome do
/// usuário, onboarding concluído, preferência de tema...).
class SettingsRepository {
  final Database _db;

  SettingsRepository(this._db);

  Future<String?> get(String key) async {
    final rows = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await get(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());
}
