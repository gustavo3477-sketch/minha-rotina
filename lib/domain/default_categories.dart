import 'models/category.dart';

/// IDs fixos das categorias de escala essenciais (seção 7: Trabalho, Folga,
/// Extra...). Fixos para que o motor de escala (Etapa 3) e as regras do
/// ciclo possam referenciá-los sem depender de uma busca por nome.
const String kWorkCategoryId = 'category-work';
const String kRestCategoryId = 'category-rest';
const String kExtraCategoryId = 'category-extra';
const String kOtherCategoryId = 'category-other';

const String kGeneralAppointmentCategoryId = 'category-general';

/// Categorias essenciais que sempre devem existir (seção 7/9: podem ser
/// renomeadas e recoloridas, mas não excluídas). Usadas para semear um
/// banco novo e para "curar" um banco que ainda não as tenha.
List<Category> defaultCoreCategories() {
  return [
    const Category(
      id: kWorkCategoryId,
      kind: CategoryKind.schedule,
      name: 'Trabalho',
      color: '#EF4444',
      icon: 'briefcase',
      classification: ScheduleClassification.work,
      isCore: true,
      sortOrder: 0,
    ),
    const Category(
      id: kRestCategoryId,
      kind: CategoryKind.schedule,
      name: 'Folga',
      color: '#22C55E',
      icon: 'leaf',
      classification: ScheduleClassification.rest,
      isCore: true,
      sortOrder: 1,
    ),
    const Category(
      id: kExtraCategoryId,
      kind: CategoryKind.schedule,
      name: 'Extra',
      color: '#3B82F6',
      icon: 'zap',
      classification: ScheduleClassification.manual,
      isCore: true,
      sortOrder: 2,
    ),
    const Category(
      id: kOtherCategoryId,
      kind: CategoryKind.schedule,
      name: 'Outro',
      color: '#F97316',
      icon: 'star',
      classification: ScheduleClassification.manual,
      isCore: true,
      sortOrder: 3,
    ),
    const Category(
      id: kGeneralAppointmentCategoryId,
      kind: CategoryKind.appointment,
      name: 'Geral',
      color: '#6B7280',
      icon: 'map-pin',
      isCore: true,
      sortOrder: 0,
    ),
  ];
}
