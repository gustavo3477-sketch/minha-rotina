import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Backup/restauração (Etapa 11, seção 16): o banco inteiro (categorias,
/// escala, exceções, compromissos e configurações — todas as tabelas) num
/// único arquivo `.db`, que a pessoa guarda onde quiser (Drive, e-mail,
/// armazenamento do aparelho...) através do compartilhamento do próprio
/// sistema. Nada é enviado a um servidor — é só um arquivo local.
///
/// Não decide sozinho ONDE colocar o arquivo exportado (isso é
/// [path_provider], uma dependência de plataforma) — quem chama passa
/// [destinationDir], o que também deixa isto testável sem precisar mockar
/// um canal de plataforma.
class BackupService {
  /// Copia o banco para um arquivo novo dentro de [destinationDir], pronto
  /// para ser compartilhado. Usa `VACUUM INTO` (não uma cópia de arquivo
  /// direta) porque o banco está aberto e em uso — `VACUUM INTO` garante um
  /// snapshot consistente mesmo assim, ao contrário de copiar o arquivo
  /// `.db` por baixo enquanto o SQLite pode estar no meio de uma escrita.
  Future<File> exportBackup(Database db, Directory destinationDir) async {
    final destPath = p.join(destinationDir.path, _backupFileName());
    await db.execute('VACUUM INTO ?', [destPath]);
    return File(destPath);
  }

  /// Substitui o arquivo do banco atual pelos bytes de [backupBytes].
  ///
  /// Fecha [currentDb] antes de sobrescrever o arquivo (não dá para
  /// sobrescrever com segurança um banco SQLite aberto) — quem chama isto
  /// precisa invalidar o provider do banco depois, para reabri-lo já com
  /// os dados restaurados.
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
