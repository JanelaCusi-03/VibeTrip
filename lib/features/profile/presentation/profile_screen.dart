import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/tag_weight.dart';
import '../../../core/router/app_routes.dart';
import '../data/user_profile_json_mapper.dart';
import '../domain/entities/user_profile.dart';
import 'user_profile_controller.dart';

/// Perfil, gustos aprendidos y privacidad (RF-16, RF-17).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  void _showExport(BuildContext context, UserProfile profile) {
    final String exportedJson = const JsonEncoder.withIndent('  ')
        .convert(UserProfileJsonMapper.toJson(profile));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mis datos'),
        content: SingleChildScrollView(
          child: SelectableText(
            exportedJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportedJson));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserProfile? profile = ref.watch(userProfileControllerProvider).value;
    final UserProfileController controller =
        ref.read(userProfileControllerProvider.notifier);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final List<TagWeight> learnedTastes = TagWeight.rankedFromVector(
      profile.currentVector,
    ).where((tagWeight) => tagWeight.weight > 0).take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Lo que más te gusta'),
            subtitle: Text(
              learnedTastes.isEmpty
                  ? 'Aún no hay suficientes datos.'
                  : learnedTastes
                      .map((tagWeight) => tagWeight.tag.displayName)
                      .join(', '),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: const Text('Interacciones registradas'),
            trailing: Text('${profile.interactionCount}'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favoritos'),
            trailing: Text('${profile.favoritePlaceIds.length}'),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Aprender de cómo uso la app'),
            subtitle:
                const Text('Telemetría implícita (tiempo de vista, etc.)'),
            value: profile.hasTelemetryConsent,
            onChanged: (hasConsent) =>
                controller.setTelemetryConsent(hasConsent: hasConsent),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exportar mis datos'),
            onTap: () => _showExport(context, profile),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reajustar mis gustos'),
            subtitle: const Text('Vuelve a hacer el onboarding.'),
            onTap: () async {
              final bool isConfirmed = await _confirm(
                context,
                title: 'Reajustar gustos',
                message: 'Se borrará lo aprendido y repetirás el onboarding. '
                    'Tus favoritos se conservan.',
                confirmLabel: 'Reajustar',
              );
              if (!isConfirmed) return;
              await controller.resetPreferences();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Eliminar todos mis datos'),
            onTap: () async {
              final bool isConfirmed = await _confirm(
                context,
                title: 'Eliminar datos',
                message: 'Se borrarán tu perfil, favoritos y eventos '
                    'pendientes de este dispositivo.',
                confirmLabel: 'Eliminar',
              );
              if (!isConfirmed) return;
              await controller.deleteAllData();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
        ],
      ),
    );
  }
}
