import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/services/backup_service.dart';
import 'package:minha_rotina/domain/models/category.dart';

void main() {
  sqfliteFfiInit();

  test(
    'exportBackup produz um arquivo com os mesmos dados do banco original',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('backup_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final db = await openAppDatabase(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      await CategoryRepository(db).ensureCoreCategories();
      await CategoryRepository(db).insert(
        const Category(
          id: 'custom-1',
          kind: CategoryKind.appointment,
          name: 'Categoria de teste',
          color: '#123456',
        ),
      );

      final exported = await BackupService().exportBackup(db, tempDir);
      await db.close();

      expect(exported.existsSync(), isTrue);

      final restoredDb = await openAppDatabase(
        path: exported.path,
        factory: databaseFactoryFfi,
      );
      final categories = await CategoryRepository(restoredDb).getAll();
      expect(categories.any((c) => c.name == 'Categoria de teste'), isTrue);
      await restoredDb.close();
    },
  );

  test(
    'restoreBackup substitui o conteúdo do arquivo do banco atual',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('backup_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbPath = '${tempDir.path}/current.db';

      final currentDb = await openAppDatabase(
        path: dbPath,
        factory: databaseFactoryFfi,
      );
      await CategoryRepository(currentDb).ensureCoreCategories();
      await CategoryRepository(currentDb).insert(
        const Category(
          id: 'to-be-lost',
          kind: CategoryKind.appointment,
          name: 'Será perdida na restauração',
          color: '#000000',
        ),
      );

      // O "backup" a restaurar é um banco totalmente separado, sem essa
      // categoria extra.
      final backupDb = await openAppDatabase(
        path: '${tempDir.path}/backup.db',
        factory: databaseFactoryFfi,
      );
      await CategoryRepository(backupDb).ensureCoreCategories();
      final backupBytes = await File(backupDb.path).readAsBytes();
      await backupDb.close();

      await BackupService().restoreBackup(currentDb, backupBytes);

      final restoredDb = await openAppDatabase(
        path: dbPath,
        factory: databaseFactoryFfi,
      );
      final categories = await CategoryRepository(restoredDb).getAll();
      expect(categories.any((c) => c.id == 'to-be-lost'), isFalse);
      await restoredDb.close();
    },
  );
}
