import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/providers.dart';
import 'category_list_page.dart';
import 'schedule_list_page.dart';

/// Aba "Ajustes" (Etapa 10/11, seção 41/16): categorias, escala, e
/// backup/restauração de todos os dados num único arquivo local.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Categorias'),
            subtitle: const Text('Nomes, cores, ícones e horários padrão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryListPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Escala'),
            subtitle: const Text('Ciclo, dias fixos e histórico de escalas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleListPage()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Backup'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exportar backup'),
            subtitle: const Text('Salva ou envia uma cópia de tudo'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Restaurar backup'),
            subtitle: const Text('Substitui os dados atuais por um backup'),
            onTap: () => _restoreBackup(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final tempDir = await getTemporaryDirectory();
      final file = await ref
          .read(backupServiceProvider)
          .exportBackup(db, tempDir);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Backup do Minha Rotina'),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar: $error')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        dialogTitle: 'Selecione o arquivo de backup',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o seletor: $error')),
        );
      }
      return;
    }
    if (picked == null) return;

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Isso substituirá TODOS os dados atuais (categorias, escala, '
          'compromissos e configurações) pelos dados deste arquivo. Esta '
          'ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final bytes = await picked.readAsBytes();
      final db = await ref.read(databaseProvider.future);
      await ref.read(backupServiceProvider).restoreBackup(db, bytes);
      ref.invalidate(databaseProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível restaurar: $error')),
        );
      }
    }
  }
}
