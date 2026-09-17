import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/repositories/settings_repository.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SettingsRepository repo;

  setUp(() async {
    db = await openAppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repo = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('get retorna null quando a chave não existe', () async {
    expect(await repo.get('nome_usuario'), isNull);
  });

  test('set/get grava e lê um valor de texto', () async {
    await repo.set('nome_usuario', 'Gustavo');
    expect(await repo.get('nome_usuario'), 'Gustavo');
  });

  test('set na mesma chave substitui o valor anterior', () async {
    await repo.set('onboarding_concluido', 'false');
    await repo.set('onboarding_concluido', 'true');
    expect(await repo.get('onboarding_concluido'), 'true');
  });

  test('getBool/setBool convertem corretamente', () async {
    expect(await repo.getBool('flag_x'), false); // padrão
    await repo.setBool('flag_x', true);
    expect(await repo.getBool('flag_x'), true);
  });
}
