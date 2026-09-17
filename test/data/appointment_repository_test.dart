import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:minha_rotina/data/local/database_helper.dart';
import 'package:minha_rotina/data/repositories/appointment_repository.dart';
import 'package:minha_rotina/data/repositories/category_repository.dart';
import 'package:minha_rotina/domain/default_categories.dart';
import 'package:minha_rotina/domain/models/appointment.dart';
import 'package:minha_rotina/domain/models/recurrence_rule.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late AppointmentRepository repo;

  setUp(() async {
    db = await openAppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await CategoryRepository(db).ensureCoreCategories();
    repo = AppointmentRepository(db);
  });

  tearDown(() => db.close());

  Appointment build({
    required String id,
    required String date,
    AppointmentKind kind = AppointmentKind.normal,
    RecurrenceRule recurrence = const RecurrenceRule(),
    double? value,
  }) {
    return Appointment(
      id: id,
      kind: kind,
      title: 'Compromisso $id',
      date: date,
      allDay: false,
      startTime: '09:00',
      endTime: '10:00',
      categoryId: kGeneralAppointmentCategoryId,
      recurrence: recurrence,
      value: value,
      createdAt: '2026-01-01T00:00:00.000',
      updatedAt: '2026-01-01T00:00:00.000',
    );
  }

  test(
    'getInRange só retorna compromissos não recorrentes dentro do intervalo',
    () async {
      await repo.insert(
        build(id: 'a', date: '2026-09-10'),
      ); // antes do intervalo
      await repo.insert(build(id: 'b', date: '2026-09-15')); // dentro
      await repo.insert(build(id: 'c', date: '2026-09-25')); // depois

      final result = await repo.getInRange('2026-09-12', '2026-09-20');
      expect(result.map((a) => a.id).toList(), ['b']);
    },
  );

  test('getInRange inclui compromissos recorrentes cuja âncora é anterior ao intervalo', () async {
    await repo.insert(
      build(
        id: 'weekly',
        date: '2026-08-01', // âncora bem antes do intervalo consultado
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      ),
    );

    final result = await repo.getInRange('2026-09-12', '2026-09-20');
    expect(result.map((a) => a.id).toList(), ['weekly']);
  });

  test(
    'trabalho extra (seção 14) guarda o valor opcional corretamente',
    () async {
      await repo.insert(
        build(
          id: 'extra-1',
          date: '2026-09-18',
          kind: AppointmentKind.extraShift,
          value: 150.5,
        ),
      );

      final loaded = await repo.getById('extra-1');
      expect(loaded!.kind, AppointmentKind.extraShift);
      expect(loaded.value, 150.5);
    },
  );

  test('search encontra por título, descrição e local (seção 43)', () async {
    await repo.insert(
      build(id: 'a', date: '2026-09-10').copyWith(description: 'Levar exames'),
    );
    await repo.insert(
      build(id: 'b', date: '2026-09-11').copyWith(location: 'Academia Central'),
    );

    expect((await repo.search('exames')).map((a) => a.id), ['a']);
    expect((await repo.search('Academia')).map((a) => a.id), ['b']);
    expect(await repo.search('não existe'), isEmpty);
  });

  test('update e delete funcionam corretamente', () async {
    await repo.insert(build(id: 'a', date: '2026-09-10'));

    final loaded = (await repo.getById('a'))!;
    await repo.update(loaded.copyWith(title: 'Novo título'));
    expect((await repo.getById('a'))!.title, 'Novo título');

    await repo.delete('a');
    expect(await repo.getById('a'), isNull);
  });

  test('um dia pode ter vários compromissos (seção 11)', () async {
    await repo.insert(build(id: 'a', date: '2026-09-17'));
    await repo.insert(build(id: 'b', date: '2026-09-17'));
    await repo.insert(build(id: 'c', date: '2026-09-17'));

    final result = await repo.getForDate('2026-09-17');
    expect(result.length, 3);
  });
}
