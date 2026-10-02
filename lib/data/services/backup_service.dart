import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'backup_service_stub.dart' if (dart.library.io) 'backup_service_io.dart' as impl;

/// Backup/restauração (Etapa 11, seção 16): o banco inteiro (categorias,
/// escala, exceções, compromissos e configurações — todas as tabelas) num
/// único arquivo, que a pessoa guarda onde quiser (Drive, e-mail,
/// armazenamento do aparelho...) através do compartilhamento do próprio
/// sistema. Nada é enviado a um servidor — é só um arquivo local.
///
/// A implementação real muda por plataforma (ver [impl]): no celular/desktop
/// usa `dart:io` direto no arquivo `.db`; na Web ainda não é suportado
/// (ver `backup_service_stub.dart`), porque o banco vive dentro do
/// IndexedDB do navegador, não num arquivo comum.
abstract class BackupService {
  factory BackupService() = impl.BackupServiceImpl;

  /// Gera uma cópia consistente do banco inteiro e devolve os bytes do
  /// arquivo, prontos para compartilhar (ex.: via `share_plus`).
  Future<Uint8List> exportBackup(Database db);

  /// Substitui o conteúdo do banco atual pelos bytes de [backupBytes].
  ///
  /// Fecha [currentDb] antes de sobrescrever o arquivo (não dá para
  /// sobrescrever com segurança um banco SQLite aberto) — quem chama isto
  /// precisa invalidar o provider do banco depois, para reabri-lo já com
  /// os dados restaurados.
  Future<void> restoreBackup(Database currentDb, Uint8List backupBytes);
}
