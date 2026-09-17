import 'package:sqflite/sqflite.dart';

import '../../domain/default_categories.dart';
import '../../domain/models/category.dart';

/// Acesso a categorias (de escala e de compromisso — seção 7/28).
///
/// A UI e o motor de escala nunca tocam no SQLite diretamente; sempre
/// passam por aqui (seção 29).
class CategoryRepository {
  final Database _db;

  CategoryRepository(this._db);

  Future<List<Category>> getAll() async {
    final rows = await _db.query('categories', orderBy: 'sort_order ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getByKind(CategoryKind kind) async {
    final rows = await _db.query(
      'categories',
      where: 'kind = ?',
      whereArgs: [kind.name],
      orderBy: 'sort_order ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final rows = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> insert(Category category) async {
    await _db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    await _db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Lança [StateError] se a categoria for essencial ([Category.isCore]) —
  /// categorias essenciais só podem ser recoloridas/renomeadas (seção 9).
  Future<void> delete(String id) async {
    final category = await getById(id);
    if (category == null) return;
    if (category.isCore) {
      throw StateError('Categorias essenciais não podem ser excluídas: $id');
    }
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Garante que as categorias essenciais (seção 7/9) existam, sem
  /// sobrescrever nenhuma que o usuário já tenha personalizado.
  Future<void> ensureCoreCategories() async {
    final existingIds = (await getAll()).map((c) => c.id).toSet();
    final missing = defaultCoreCategories().where(
      (c) => !existingIds.contains(c.id),
    );
    for (final category in missing) {
      await insert(category);
    }
  }
}
