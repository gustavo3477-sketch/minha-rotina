import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/date_utils.dart' as dutil;
import '../../domain/models/appointment.dart';

const _channelId = 'compromissos';
const _channelName = 'Compromissos';
const _channelDescription = 'Lembretes de compromissos e trabalho extra';

/// Lembretes locais de compromissos (Etapa 9, seção 12).
///
/// Só Android por enquanto: iOS precisa de configuração própria (permissões,
/// Info.plist) que só é seguro fazer na Etapa 14 (preparação iOS), quando
/// houver como testar de fato num Mac. Todo método aqui é um no-op seguro em
/// qualquer outra plataforma (inclusive Windows/web, usados só como preview
/// de desenvolvimento — nunca foram alvo real de notificações).
///
/// Não agenda lembretes de compromissos recorrentes (seção 13): repetir um
/// lembrete para toda ocorrência futura exigiria reagendamento periódico em
/// segundo plano (ex.: WorkManager), o que é uma funcionalidade própria fora
/// do escopo desta etapa — limitação documentada, não uma omissão silenciosa.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_isSupportedPlatform || _initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Agenda (ou cancela, se não se aplicar mais) o lembrete de [appointment].
  Future<void> scheduleForAppointment(Appointment appointment) async {
    if (!_isSupportedPlatform) return;

    final minutesBefore = appointment.reminderMinutesBefore;
    final anchor = _reminderAnchor(appointment);
    if (minutesBefore == null ||
        appointment.recurrence.isRecurring ||
        anchor == null) {
      await cancelForAppointment(appointment.id);
      return;
    }

    final fireAt = anchor.subtract(Duration(minutes: minutesBefore));
    final scheduled = tz.TZDateTime.from(fireAt, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      await cancelForAppointment(appointment.id);
      return;
    }

    await initialize();
    await _plugin.zonedSchedule(
      id: _notificationId(appointment.id),
      scheduledDate: scheduled,
      title: appointment.title,
      body: _body(appointment),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
      ),
      // "inexact" evita depender da permissão de alarme exato (Android
      // 12+, restrita ainda mais no 13+): um lembrete alguns minutos
      // atrasado é aceitável aqui, e exigir essa permissão sensível para
      // um app de agenda pessoal seria desproporcional.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelForAppointment(String appointmentId) async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancel(id: _notificationId(appointmentId));
  }

  /// O instante (hora local) ao qual o lembrete de [appointment] se refere:
  /// o horário de início, ou 09:00 do dia quando for um compromisso de dia
  /// todo (não há horário próprio para ancorar o lembrete nesse caso).
  DateTime? _reminderAnchor(Appointment appointment) {
    final date = dutil.fromIsoDate(appointment.date);
    if (appointment.allDay) {
      return DateTime(date.year, date.month, date.day, 9);
    }
    final startTime = appointment.startTime;
    if (startTime == null) return null;
    final parts = startTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _body(Appointment appointment) {
    if (appointment.location != null && appointment.location!.isNotEmpty) {
      return appointment.location!;
    }
    if (appointment.allDay) return 'Hoje';
    return appointment.startTime ?? '';
  }

  int _notificationId(String appointmentId) =>
      appointmentId.hashCode & 0x7fffffff;
}
