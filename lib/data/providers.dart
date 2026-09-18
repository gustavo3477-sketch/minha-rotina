import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/database_helper.dart';
import 'repositories/appointment_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/notification_service.dart';

/// Abre o banco uma única vez por execução do app. A tela raiz espera este
/// provider carregar antes de mostrar qualquer tela real — ver
/// [databaseProvider.when] no widget de bootstrap.
final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await openAppDatabase();
  ref.onDispose(db.close);

  final categoryRepo = CategoryRepository(db);
  await categoryRepo.ensureCoreCategories();

  return db;
});

/// As telas (via controllers/notifiers) só conhecem os repositórios — nunca
/// o [Database] ou SQL diretamente (seção 29).
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CategoryRepository(db);
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return ScheduleRepository(db);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return AppointmentRepository(db);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SettingsRepository(db);
});

/// Uma única instância para o app inteiro (Etapa 9) — permite sobrescrever
/// com um fake nos testes de widget, em vez de bater no plugin real.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
