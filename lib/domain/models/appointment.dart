import 'recurrence_rule.dart';

/// [AppointmentKind.extraShift] cobre "trabalho extra" (seção 14): reaproveita
/// a mesma tabela/entidade de compromisso (com o campo [Appointment.value]
/// adicional), em vez de criar uma tabela paralela quase idêntica — a seção
/// 28 não lista "trabalhos extras" como entidade própria, e a seção 52 pede
/// para evitar sistemas duplicados desnecessários.
enum AppointmentKind { normal, extraShift }

/// Um compromisso (seção 11/12) ou trabalho extra (seção 14).
///
/// Vários compromissos podem existir no mesmo dia — nunca há limite de 1
/// por dia (seção 11).
class Appointment {
  final String id;
  final AppointmentKind kind;
  final String title;

  /// Data-âncora (ISO yyyy-MM-dd). Para compromissos recorrentes, é a
  /// primeira ocorrência — as demais são calculadas (Etapa 7), não
  /// duplicadas no banco.
  final String date;

  final bool allDay;
  final String? startTime;
  final String? endTime;
  final String? categoryId;
  final String? location;
  final String? description;
  final RecurrenceRule recurrence;

  /// Minutos de antecedência do lembrete (0 = na hora). Nulo = sem lembrete.
  /// Seção 12 já prevê múltiplos lembretes no futuro; por ora, um só.
  final int? reminderMinutesBefore;

  /// Valor opcional do trabalho extra (seção 14). Só relevante quando
  /// [kind] é [AppointmentKind.extraShift].
  final double? value;

  final String createdAt;
  final String updatedAt;

  const Appointment({
    required this.id,
    required this.kind,
    required this.title,
    required this.date,
    required this.allDay,
    this.startTime,
    this.endTime,
    this.categoryId,
    this.location,
    this.description,
    this.recurrence = const RecurrenceRule(),
    this.reminderMinutesBefore,
    this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  Appointment copyWith({
    String? title,
    String? date,
    bool? allDay,
    String? startTime,
    String? endTime,
    String? categoryId,
    String? location,
    String? description,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    double? value,
    String? updatedAt,
  }) {
    return Appointment(
      id: id,
      kind: kind,
      title: title ?? this.title,
      date: date ?? this.date,
      allDay: allDay ?? this.allDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      value: value ?? this.value,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'date': date,
      'all_day': allDay ? 1 : 0,
      'start_time': startTime,
      'end_time': endTime,
      'category_id': categoryId,
      'location': location,
      'description': description,
      ...recurrence.toMap(),
      'reminder_minutes_before': reminderMinutesBefore,
      'value': value,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Appointment.fromMap(Map<String, Object?> map) {
    return Appointment(
      id: map['id'] as String,
      kind: AppointmentKind.values.firstWhere((v) => v.name == map['kind']),
      title: map['title'] as String,
      date: map['date'] as String,
      allDay: (map['all_day'] as int) == 1,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      categoryId: map['category_id'] as String?,
      location: map['location'] as String?,
      description: map['description'] as String?,
      recurrence: RecurrenceRule.fromMap(map),
      reminderMinutesBefore: map['reminder_minutes_before'] as int?,
      value: map['value'] as double?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
