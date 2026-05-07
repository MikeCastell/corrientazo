import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/env/app_env.dart';
import '../../../core/networking/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../media/data/media_repository.dart';
import '../application/cook_profile_controller.dart';
import '../data/cook_profile_repository.dart';

class CookProfileScreen extends ConsumerStatefulWidget {
  const CookProfileScreen({super.key});

  @override
  ConsumerState<CookProfileScreen> createState() => _CookProfileScreenState();
}

class _CookProfileScreenState extends ConsumerState<CookProfileScreen> {
  final _businessName = TextEditingController();
  final _bio = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _hydrate(CookProfileDto p) {
    if (_businessName.text.isEmpty) {
      _businessName.text = p.userName ?? '';
    }
    if (_bio.text.isEmpty) {
      _bio.text = p.bio ?? '';
    }
  }

  Future<void> _pickAndUploadAvatar(CookProfileDto p) async {
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (x == null) return;

      final url = await ref
          .read(mediaRepositoryProvider)
          .uploadImage(File(x.path));
      await ref
          .read(cookProfileControllerProvider.notifier)
          .save(avatarUrl: url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto actualizada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pudimos subir la foto. ($e)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      await ref
          .read(cookProfileControllerProvider.notifier)
          .save(
            businessName: _businessName.text.trim().isEmpty
                ? null
                : _businessName.text.trim(),
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(cookProfileControllerProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('No pudimos cargar el perfil. $e'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(cookProfileControllerProvider.notifier).refresh(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (p) {
        _hydrate(p);
        final avatarUrl = p.userAvatarUrl;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _saving ? null : () => _pickAndUploadAvatar(p),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.10),
                          border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.18),
                          ),
                        ),
                        child: avatarUrl == null
                            ? const Icon(Icons.person, color: AppColors.brand)
                            : Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      color: AppColors.brand,
                                    ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.userName ?? 'Tu cocina',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.userPhone ?? '—',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _saving
                              ? 'Guardando…'
                              : 'Toca la foto para cambiarla',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identidad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _businessName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del negocio (o tu nombre)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText:
                          'Bio corta (ej: “Sazón casera, porción generosa”)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (AppEnv.startupDebug) ...[
              Text(
                'DEBUG: avatarUrl=$avatarUrl',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _saving
                    ? null
                    : () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Cerrar sesión'),
              ),
            ),
          ],
        );
      },
    );
  }
}
