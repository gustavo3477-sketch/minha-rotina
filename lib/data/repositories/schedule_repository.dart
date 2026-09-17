import 'package:sqflite/sqflite.dart';

import '../../domain/models/cycle_position.dart';
import '../../domain/models/fixed_day_rule.dart';
import '../../domain/models/schedule_exception.dart';
import '../../domain/models/schedule_version.dart';

/// Acesso a escalas (versões, posições do ciclo, regras fixas) e exceções
/// manuais (seção 5/6/28/39/40).
///
/// O CÁLCULO da escala (o "motor") não vive aqui — isso é o `ScheduleEngine`
/// da Etapa 3. Este repositório só lê e grava a CONFIGURAÇÃO (nunca gera
/// nem persiste dias futuros — seção 38).
class ScheduleRepository {
  final Database _db;

  ScheduleRepository(this._db);

  Future<List<ScheduleVersion>> getAllVersions() async {
    final rows = await _db.query(
      'schedule_versions',
      orderBy: 'effective_from ASC',
    );
    final versions = <ScheduleVersion>[];
    for (final row in rows) {
      versions.add(await _hydrate(row));
    }
    return versions;
  }

  Future<ScheduleVersion?> getVersionById(String id) async {
    final rows = await _db.query(
      'schedule_versions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<ScheduleVersion> _hydrate(Map<String, Object?> row) async {
    final id = row['id'] as String;
    final positionRows = await _db.query(
      'cycle_positions',
      where: 'schedule_version_id = ?',
      whereArgs: [id],
      orderBy: 'order_index ASC',
    );
    final ruleRows = await _db.query(
      'fixed_day_rules',
      where: 'schedule_version_id = ?',
      whereArgs: [id],
    );
    return ScheduleVersion.fromMap(
      row,
      cyclePositions: positionRows.map(CyclePosition.fromMap).toList(),
      fixedDayRules: ruleRows.map(FixedDayRule.fromMap).toList(),
    );
  }

  Future<void> insertVersion(ScheduleVersion version) async {
    await _db.transaction((txn) async {
      await txn.insert('schedule_versions', version.toMap());
      for (final position in version.cyclePositions) {
        await txn.insert('cycle_positions', position.toMap());
      }
      for (final rule in version.fixedDayRules) {
        await txn.insert('fixed_day_rules', rule.toMap());
      }
    });
  }

  /// Substitui cabeçalho, posições do ciclo e regras fixas da versão.
  /// Simples de raciocinar (poucas linhas por escala) e correto mesmo
  /// quando posições são adicionadas/removidas.
  Future<void> updateVersion(ScheduleVersion version) async {
    await _db.transaction((txn) async {
      await txn.update(
        'schedule_versions',
        version.toMap(),
        where: 'id = ?',
        whereArgs: [version.id],
      );
      await txn.delete(
        'cycle_positions',
        where: 'schedule_version_id = ?',
        whereArgs: [version.id],
      );
      for (final position in version.cyclePositions) {
        await txn.insert('cycle_positions', position.toMap());
      }
      await txn.delete(
        'fixed_day_rules',
        where: 'schedule_version_id = ?',
        whereArgs: [version.id],
      );
      for (final rule in version.fixedDayRules) {
        await txn.insert('fixed_day_rules', rule.toMap());
      }
    });
  }

  // ---- Exceções manuais (seção 39) ----

  Future<ScheduleException?> getExceptionForDate(String date) async {
    final rows = await _db.query(
      'schedule_exceptions',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (rows.isEmpty) return null;
    return ScheduleException.fromMap(rows.first);
  }

  Future<List<ScheduleException>> getExceptionsInRange(
    String startDate,
    String endDate,
  ) async {
    final rows = await _db.query(
      'schedule_exceptions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
    );
    return rows.map(ScheduleException.fromMap).toList();
  }

  /// Cria ou substitui a exceção da data (nunca duplica — uma exceção por
  /// dia, seção 39).
  Future<void> upsertException(ScheduleException exception) async {
    await _db.insert(
      'schedule_exceptions',
      exception.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeExceptionForDate(String date) async {
    await _db.delete(
      'schedule_exceptions',
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}
