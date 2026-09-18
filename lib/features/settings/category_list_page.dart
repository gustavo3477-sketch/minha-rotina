import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_icons.dart';
import '../../core/color_utils.dart';
import '../../data/providers.dart';
import '../../domain/models/category.dart';
import '../../domain/providers.dart';
import 'category_form_page.dart';

/// Lista de categorias (seção 7/9), separadas por tipo. Essenciais têm um
/// selo de "não pode excluir" mas continuam editáveis (nome/cor/ícone).
class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
        data: (categories) {
          final scheduleCategories =
              categories.where((c) => c.kind == CategoryKind.schedule).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final appointmentCategories =
              categories
                  .where((c) => c.kind == CategoryKind.appointment)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              _SectionHeader(
                title: 'Categorias de escala',
                subtitle: 'Usadas no ciclo e nos dias fixos da sua escala',
              ),
              for (final category in scheduleCategories)
                _CategoryTile(category: category),
              _AddButton(
                label: 'Adicionar categoria de escala',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryFormPage(kind: CategoryKind.schedule),
                  ),
                ),
              ),
              const Divider(height: 32),
              _SectionHeader(
                title: 'Categorias de compromisso',
                subtitle: 'Etiquetas opcionais para os seus compromissos',
              ),
              for (final category in appointmentCategories)
                _CategoryTile(category: category),
              _AddButton(
                label: 'Adicionar categoria de compromisso',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoryFormPage(kind: CategoryKind.appointment),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorFromHex(category.color);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          iconForName(category.icon),
          color: contrastingTextColor(color),
        ),
      ),
      title: Text(category.name),
      subtitle: category.isCore
          ? const Text('Essencial — não pode excluir')
          : null,
      trailing: category.isCore
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CategoryFormPage(kind: category.kind, existing: category),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    if (category.kind == CategoryKind.schedule) {
      final versions = await ref.read(scheduleVersionsProvider.future);
      final inUse = versions.any(
        (v) =>
            v.cyclePositions.any((p) => p.categoryId == category.id) ||
            v.fixedDayRules.any((r) => r.categoryId == category.id),
      );
      if (inUse) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Categoria em uso'),
            content: const Text(
              'Esta categoria está sendo usada na sua escala (num dia do '
              'ciclo ou num dia fixo). Altere isso em Ajustes > Escala antes '
              'de excluí-la.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text(
          '"${category.name}" será removida. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(categoryRepositoryProvider).delete(category.id);
    ref.invalidate(categoriesProvider);
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: Text(label),
      onTap: onTap,
    );
  }
}
