import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';

/// Versão web — ver [BackupService]. Backup ainda não está disponível na
/// versão web (não tem como gravar/ler o arquivo do banco do mesmo jeito
/// que no celular); fica para quando o formato virar JSON.
class BackupServiceImpl implements BackupService {
  @override
  Future<Uint8List> exportBackup(Database db) {
    throw UnsupportedError(
      'Backup ainda não está disponível na versão web do Minha Rotina.',
    );
  }

  @override
  Future<void> restoreBackup(Database currentDb, Uint8List backupBytes) {
    throw UnsupportedError(
      'Restauração ainda não está disponível na versão web do Minha Rotina.',
    );
  }
}
