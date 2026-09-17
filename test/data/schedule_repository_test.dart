import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/data/repositories/schedule_repository.dart';
import 'package:minha_rotina/domain/default_categories.dart';
import 'package:minha_rotina/domain/models/cycle_position.dart';
import 'package:minha_rotina/domain/models/fixed_day_rule.dart';
import 'package:minha_rotina/domain/models/schedule_exception.dart';
import 'package:minha_rotina/domain/models/schedule_version.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late ScheduleRepository repo;

  setUp(() async {
    db = await openAppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await CategoryRepository(db).ensureCoreCategories();
    repo = ScheduleRepository(db);
  });

  tearDown(() => db.close());

  ScheduleVersion build2x2({
    String id = 'version-1',
    String effectiveFrom = '2026-01-01',
  }) {
    return ScheduleVersion(
      id: id,
      name: 'Minha escala',
      effectiveFrom: effectiveFrom,
      referenceDate: '2026-01-01',
      referencePositionIndex: 0,
      cyclePositions: [
        CyclePosition(
          id: '$id-p1',
          scheduleVersionId: id,
          order: 1,
          categoryId: kWorkCategoryId,
          startTime: '13:00',
          endTime: '01:00',
        ),
        CyclePosition(
          id: '$id-p2',
          scheduleVersionId: id,
          order: 2,
          categoryId: kWorkCategoryId,
          startTime: '13:00',
          endTime: '01:00',
        ),
        CyclePosition(
          id: '$id-p3',
          scheduleVersionId: id,
          order: 3,
          categoryId: kRestCategoryId,
        ),
        CyclePosition(
          id: '$id-p4',
          scheduleVersionId: id,
          order: 4,
          categoryId: kRestCategoryId,
        ),
      ],
      fixedDayRules: [
        FixedDayRule(
          id: '$id-r1',
          scheduleVersionId: id,
          weekday: 7,
          enabled: true,
          categoryId: kRestCategoryId,
        ),
      ],
    );
  }

  test(
    'insertVersion grava cabeçalho, posições do ciclo e regras fixas',
    () async {
      await repo.insertVersion(build2x2());

      final loaded = await repo.getVersionById('version-1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Minha escala');
      expect(loaded.cyclePositions.length, 4);
      expect(loaded.fixedDayRules.length, 1);
      expect(loaded.sortedCyclePositions.first.order, 1);
    },
  );

  test(
    'updateVersion substitui as posições antigas em vez de duplicar',
    () async {
      await repo.insertVersion(build2x2());
      var version = (await repo.getVersionById('version-1'))!;

      // Simula uma escala 3x3: adiciona uma posição de trabalho e uma de folga.
      final updated = version.copyWith(
        cyclePositions: [
          ...version.cyclePositions,
          CyclePosition(
            id: 'version-1-p5',
            scheduleVersionId: 'version-1',
            order: 5,
            categoryId: kWorkCategoryId,
          ),
          CyclePosition(
            id: 'version-1-p6',
            scheduleVersionId: 'version-1',
            order: 6,
            categoryId: kRestCategoryId,
          ),
        ],
      );
      await repo.updateVersion(updated);

      final reloaded = (await repo.getVersionById('version-1'))!;
      expect(reloaded.cyclePositions.length, 6);
    },
  );

  test(
    'getAllVersions ordena por effectiveFrom (seção 40: mudança de escala)',
    () async {
      await repo.insertVersion(
        build2x2(id: 'version-b', effectiveFrom: '2026-07-01'),
      );
      await repo.insertVersion(
        build2x2(id: 'version-a', effectiveFrom: '2026-01-01'),
      );

      final all = await repo.getAllVersions();
      expect(all.map((v) => v.id).toList(), ['version-a', 'version-b']);
    },
  );

  test(
    'upsertException nunca duplica: a segunda chamada substitui a primeira',
    () async {
      await repo.upsertException(
        ScheduleException(
          id: 'exc-1',
          date: '2026-09-18',
          categoryId: kExtraCategoryId,
          originalCategoryId: kRestCategoryId,
          createdAt: '2026-09-18T00:00:00.000',
        ),
      );
      await repo.upsertException(
        ScheduleException(
          id: 'exc-2', // id diferente, mesma data
          date: '2026-09-18',
          categoryId: kOtherCategoryId,
          originalCategoryId: kRestCategoryId,
          createdAt: '2026-09-18T01:00:00.000',
        ),
      );

      final all = await repo.getExceptionsInRange('2026-09-01', '2026-09-30');
      expect(all.length, 1);
      expect(all.first.categoryId, kOtherCategoryId);
    },
  );

  test('removeExceptionForDate faz o dia voltar a depender só do cálculo automático', () async {
    await repo.upsertException(
      ScheduleException(
        id: 'exc-1',
        date: '2026-09-18',
        categoryId: kExtraCategoryId,
        originalCategoryId: kRestCategoryId,
        createdAt: '2026-09-18T00:00:00.000',
      ),
    );
    expect(await repo.getExceptionForDate('2026-09-18'), isNotNull);

    await repo.removeExceptionForDate('2026-09-18');
    expect(await repo.getExceptionForDate('2026-09-18'), isNull);
  });
}
