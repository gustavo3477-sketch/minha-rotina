import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Versão atual do schema. Toda mudança de estrutura soma 1 aqui e adiciona
/// um `if (oldVersion < N)` em [_onUpgrade] — nunca edita uma migration já
/// publicada (seção 28: "utilizar migrations/versionamento do banco").
const int kDatabaseVersion = 1;
const String kDatabaseFileName = 'minha_rotina.db';

/// Abre (criando se necessário) o banco SQLite local do Minha Rotina.
///
/// Em produção, [path] é omitido e o arquivo fica na pasta de dados do app
/// (offline, por dispositivo). Em testes, [path] pode apontar para um banco
/// em memória (`inMemoryDatabasePath`) usando `sqflite_common_ffi`.
Future<Database> openAppDatabase({
  String? path,
  DatabaseFactory? factory,
}) async {
  final resolvedPath =
      path ??
      (kIsWeb
          ? kDatabaseFileName
          : p.join(
              (await getApplicationDocumentsDirectory()).path,
              kDatabaseFileName,
            ));

  final options = OpenDatabaseOptions(
    version: kDatabaseVersion,
    onCreate: (db, version) async {
      await _createSchema(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Exemplo para o futuro:
      // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
    },
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );

  // Mesma chamada (via DatabaseFactory) tanto para o app real quanto para
  // testes com sqflite_common_ffi — evita duas assinaturas diferentes. Na
  // Web não existe arquivo de verdade: o sqflite_common_ffi_web grava tudo
  // num banco SQLite compilado para WASM, persistido no IndexedDB do
  // navegador.
  final resolvedFactory = factory ?? (kIsWeb ? databaseFactoryFfiWeb : databaseFactory);
  return resolvedFactory.openDatabase(resolvedPath, options: options);
}

Future<void> _createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL,
      name TEXT NOT NULL,
      color TEXT NOT NULL,
      icon TEXT,
      default_start_time TEXT,
      default_end_time TEXT,
      classification TEXT,
      is_core INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE schedule_versions (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      effective_from TEXT NOT NULL,
      reference_date TEXT NOT NULL,
      reference_position_index INTEGER NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_schedule_versions_effective_from ON schedule_versions(effective_from)',
  );

  await db.execute('''
    CREATE TABLE cycle_positions (
      id TEXT PRIMARY KEY,
      schedule_version_id TEXT NOT NULL REFERENCES schedule_versions(id) ON DELETE CASCADE,
      order_index INTEGER NOT NULL,
      category_id TEXT NOT NULL REFERENCES categories(id),
      name_override TEXT,
      start_time TEXT,
      end_time TEXT
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_cycle_positions_version ON cycle_positions(schedule_version_id)',
  );

  await db.execute('''
    CREATE TABLE fixed_day_rules (
      id TEXT PRIMARY KEY,
      schedule_version_id TEXT NOT NULL REFERENCES schedule_versions(id) ON DELETE CASCADE,
      weekday INTEGER NOT NULL,
      enabled INTEGER NOT NULL,
      category_id TEXT NOT NULL REFERENCES categories(id)
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_fixed_day_rules_version ON fixed_day_rules(schedule_version_id)',
  );

  await db.execute('''
    CREATE TABLE schedule_exceptions (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL UNIQUE,
      category_id TEXT NOT NULL REFERENCES categories(id),
      original_category_id TEXT NOT NULL REFERENCES categories(id),
      reason TEXT,
      start_time TEXT,
      end_time TEXT,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_schedule_exceptions_date ON schedule_exceptions(date)',
  );

  await db.execute('''
    CREATE TABLE appointments (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      all_day INTEGER NOT NULL,
      start_time TEXT,
      end_time TEXT,
      category_id TEXT REFERENCES categories(id),
      location TEXT,
      description TEXT,
      recurrence_frequency TEXT NOT NULL DEFAULT 'none',
      recurrence_interval INTEGER,
      recurrence_weekdays TEXT,
      recurrence_until TEXT,
      recurrence_count INTEGER,
      reminder_minutes_before INTEGER,
      value REAL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  // Consultas por intervalo de datas (seção 37: nunca carregar tudo).
  await db.execute('CREATE INDEX idx_appointments_date ON appointments(date)');

  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''');
}
