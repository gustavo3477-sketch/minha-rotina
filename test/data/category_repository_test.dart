import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/domain/default_categories.dart';
import 'package:minha_rotina/domain/models/category.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late CategoryRepository repo;

  setUp(() async {
    db = await openAppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repo = CategoryRepository(db);
  });

  tearDown(() => db.close());

  test(
    'ensureCoreCategories semeia as 5 categorias essenciais uma única vez',
    () async {
      await repo.ensureCoreCategories();
      await repo.ensureCoreCategories(); // idempotente — não deve duplicar

      final all = await repo.getAll();
      expect(all.length, 5);
      expect(all.where((c) => c.isCore).length, 5);
    },
  );

  test(
    'ensureCoreCategories não sobrescreve uma categoria já personalizada',
    () async {
      await repo.ensureCoreCategories();
      final work = (await repo.getById(kWorkCategoryId))!;
      await repo.update(work.copyWith(name: 'Plantão', color: '#000000'));

      await repo
          .ensureCoreCategories(); // roda de novo, como no próximo start do app

      final reloaded = (await repo.getById(kWorkCategoryId))!;
      expect(reloaded.name, 'Plantão');
      expect(reloaded.color, '#000000');
    },
  );

  test('getByKind separa categorias de escala e de compromisso', () async {
    await repo.ensureCoreCategories();
    final scheduleCats = await repo.getByKind(CategoryKind.schedule);
    final appointmentCats = await repo.getByKind(CategoryKind.appointment);

    expect(scheduleCats.length, 4);
    expect(appointmentCats.length, 1);
  });

  test('categoria essencial não pode ser excluída', () async {
    await repo.ensureCoreCategories();
    // repo.delete é async: o StateError só aparece quando o Future é
    // resolvido, então passamos o Future em si para o expect (e não uma
    // closure) — do contrário o matcher nunca captura o erro.
    await expectLater(repo.delete(kWorkCategoryId), throwsStateError);

    final stillThere = await repo.getById(kWorkCategoryId);
    expect(stillThere, isNotNull);
  });

  test(
    'categoria personalizada (não essencial) pode ser criada e excluída',
    () async {
      const custom = Category(
        id: 'category-custom-1',
        kind: CategoryKind.schedule,
        name: 'Plantão 12h',
        color: '#A855F7',
        classification: ScheduleClassification.manual,
      );
      await repo.insert(custom);

      expect(await repo.getById('category-custom-1'), isNotNull);

      await repo.delete('category-custom-1');
      expect(await repo.getById('category-custom-1'), isNull);
    },
  );
}
