/// Para qual finalidade a categoria pode ser usada.
///
/// Uma categoria de escala representa a classificação de um DIA inteiro
/// (Trabalho, Folga, Extra...) — mutuamente exclusiva por dia. Uma categoria
/// de compromisso é apenas uma etiqueta em um evento (Academia, Médico...) —
/// um dia pode ter vários compromissos com categorias diferentes.
///
/// As duas vivem na mesma tabela (evita duplicar a estrutura), diferenciadas
/// por este campo.
enum CategoryKind { schedule, appointment }

/// Classificação interna de uma categoria de escala.
///
/// Separada do [Category.name] (que o usuário pode renomear livremente) para
/// que o motor de escala continue sabendo o que cada categoria REPRESENTA
/// mesmo depois de renomeada. Só é relevante para [CategoryKind.schedule].
enum ScheduleClassification { work, rest, manual }

CategoryKind categoryKindFromDb(String value) =>
    CategoryKind.values.firstWhere((v) => v.name == value);

ScheduleClassification? scheduleClassificationFromDb(String? value) {
  if (value == null) return null;
  return ScheduleClassification.values.firstWhere((v) => v.name == value);
}

/// Uma categoria configurável (seção 7 do briefing): nome, cor, ícone e
/// horário padrão opcional. Nunca fica presa no código — tudo é editável.
class Category {
  final String id;
  final CategoryKind kind;
  final String name;

  /// Cor em hex, ex.: "#EF4444".
  final String color;

  /// Nome do ícone (ex.: "briefcase"). Opcional.
  final String? icon;

  /// Horário padrão da jornada, quando esta categoria é usada na escala
  /// (seção 8: "TRABALHO 13:00 → 01:00").
  final String? defaultStartTime;
  final String? defaultEndTime;

  /// Só usado quando [kind] é [CategoryKind.schedule].
  final ScheduleClassification? classification;

  /// Categorias essenciais (Trabalho, Folga, Extra, Outro) não podem ser
  /// excluídas pelo usuário — só renomeadas/recoloridas.
  final bool isCore;

  final int sortOrder;

  const Category({
    required this.id,
    required this.kind,
    required this.name,
    required this.color,
    this.icon,
    this.defaultStartTime,
    this.defaultEndTime,
    this.classification,
    this.isCore = false,
    this.sortOrder = 0,
  });

  /// Uma jornada que atravessa a meia-noite (seção 8), ex.: 13:00 → 01:00.
  bool get crossesMidnight {
    if (defaultStartTime == null || defaultEndTime == null) return false;
    return defaultEndTime!.compareTo(defaultStartTime!) < 0;
  }

  Category copyWith({
    String? name,
    String? color,
    String? icon,
    String? defaultStartTime,
    String? defaultEndTime,
    ScheduleClassification? classification,
    bool? isCore,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      kind: kind,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      defaultStartTime: defaultStartTime ?? this.defaultStartTime,
      defaultEndTime: defaultEndTime ?? this.defaultEndTime,
      classification: classification ?? this.classification,
      isCore: isCore ?? this.isCore,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kind': kind.name,
      'name': name,
      'color': color,
      'icon': icon,
      'default_start_time': defaultStartTime,
      'default_end_time': defaultEndTime,
      'classification': classification?.name,
      'is_core': isCore ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as String,
      kind: categoryKindFromDb(map['kind'] as String),
      name: map['name'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String?,
      defaultStartTime: map['default_start_time'] as String?,
      defaultEndTime: map['default_end_time'] as String?,
      classification: scheduleClassificationFromDb(
        map['classification'] as String?,
      ),
      isCore: (map['is_core'] as int) == 1,
      sortOrder: map['sort_order'] as int,
    );
  }
}
