import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';

/// Implementação real (Android/iOS/Windows/desktop) — ver [BackupService].
class BackupServiceImpl implements BackupService {
  /// Usa `VACUUM INTO` (não uma cópia de arquivo direta) porque o banco
  /// está aberto e em uso — `VACUUM INTO` garante um snapshot consistente
  /// mesmo assim, ao contrário de copiar o arquivo `.db` por baixo
  /// enquanto o SQLite pode estar no meio de uma escrita. O arquivo
  /// temporário existe só o tempo de ler os bytes de volta; usa
  /// `Directory.systemTemp` (dart:io puro) em vez de path_provider para não
  /// depender de um canal de plataforma só para isso.
  @override
  Future<Uint8List> exportBackup(Database db) async {
    final tempDir = Directory.systemTemp;
    final tempPath = p.join(tempDir.path, _backupFileName());
    final tempFile = File(tempPath);
    try {
      await db.execute('VACUUM INTO ?', [tempPath]);
      return await tempFile.readAsBytes();
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  @override
  Future<void> restoreBackup(Database currentDb, Uint8List backupBytes) async {
    final dbPath = currentDb.path;
    await currentDb.close();
    await File(dbPath).writeAsBytes(backupBytes, flush: true);
  }

  String _backupFileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'minha_rotina_backup_$stamp.db';
  }
}
