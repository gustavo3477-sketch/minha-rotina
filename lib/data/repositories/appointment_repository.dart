import 'package:sqflite/sqflite.dart';

import '../../domain/models/appointment.dart';

/// Acesso a compromissos e trabalhos extras (seção 11/12/14/28).
///
/// Consultas SEMPRE por intervalo de datas (seção 37: nunca carregar todo
/// o histórico de uma vez). A expansão de recorrências (seção 13, Etapa 7)
/// acontece em uma camada acima, não aqui — este repositório só lê/grava a
/// ocorrência-âncora de cada compromisso.
class AppointmentRepository {
  final Database _db;

  AppointmentRepository(this._db);

  /// Compromissos cuja data-âncora cai no intervalo, OU que são recorrentes
  /// e começaram antes do intervalo (para a expansão de recorrência
  /// conseguir gerar as ocorrências dentro do intervalo).
  Future<List<Appointment>> getInRange(String startDate, String endDate) async {
    // Não-recorrentes: precisam cair dentro do intervalo. Recorrentes:
    // qualquer âncora até o fim do intervalo pode gerar ocorrências dentro
    // dele (a expansão em si fica na camada de agenda, não aqui).
    final rows = await _db.query(
      'appointments',
      where:
          "(recurrence_frequency = 'none' AND date >= ? AND date <= ?) "
          "OR (recurrence_frequency != 'none' AND date <= ?)",
      whereArgs: [startDate, endDate, endDate],
      orderBy: 'date ASC',
    );
    return rows.map(Appointment.fromMap).toList();
  }

  Future<List<Appointment>> getForDate(String date) => getInRange(date, date);

  Future<Appointment?> getById(String id) async {
    final rows = await _db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Appointment.fromMap(rows.first);
  }

  /// Busca por título, descrição ou local (seção 43). A UI filtra por
  /// categoria/período combinando isto com os outros métodos.
  Future<List<Appointment>> search(String query) async {
    final like = '%$query%';
    final rows = await _db.query(
      'appointments',
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'date ASC',
    );
    return rows.map(Appointment.fromMap).toList();
  }

  Future<void> insert(Appointment appointment) async {
    await _db.insert('appointments', appointment.toMap());
  }

  Future<void> update(Appointment appointment) async {
    await _db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}
