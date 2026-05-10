import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/networking/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../media/data/media_repository.dart';
import '../application/cook_profile_controller.dart';
import '../data/cook_profile_repository.dart';
import '../application/cook_meals_controller.dart';
import '../domain/cook_meal.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/marketplace/food_image.dart';

class CookProfileScreen extends ConsumerStatefulWidget {
  const CookProfileScreen({super.key});

  @override
  ConsumerState<CookProfileScreen> createState() => _CookProfileScreenState();
}

class _CookProfileScreenState extends ConsumerState<CookProfileScreen> {
  final _businessName = TextEditingController();
  final _bio = TextEditingController();

  bool _saving = false;
  bool _editing = false;

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
    final meals = ref.watch(cookMealsControllerProvider);

    return profile.when(
      loading: () => const _CookProfileLoading(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _PageHeader(
              title: 'Tu cocina',
              subtitle: 'Tu historia es parte del sabor.',
              trailing: IconButton(
                tooltip: 'Reintentar',
                onPressed: () =>
                    ref.read(cookProfileControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No pudimos cargar tu perfil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => ref
                          .read(cookProfileControllerProvider.notifier)
                          .refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (p) {
        _hydrate(p);
        final avatarUrl = p.userAvatarUrl;
        final cookName = (p.userName ?? 'Tu cocina').trim();
        final bio = (_bio.text.trim().isEmpty ? (p.bio ?? '') : _bio.text)
            .trim();
        final warmBio = bio.isEmpty
            ? 'Cocinando sabores caseros con cariño, como en casa. 🍲'
            : bio;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(cookProfileControllerProvider.notifier).refresh();
              await ref.read(cookMealsControllerProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _CookHero(
                    avatarUrl: avatarUrl,
                    name: cookName,
                    subtitle: warmBio,
                    saving: _saving,
                    onTapAvatar: _saving ? null : () => _pickAndUploadAvatar(p),
                    onToggleEdit: () {
                      HapticFeedback.selectionClick();
                      setState(() => _editing = !_editing);
                    },
                    editing: _editing,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _BadgePill(label: 'Casero'),
                        _BadgePill(label: 'Favorito del barrio'),
                        _BadgePill(label: 'Recién hecho'),
                        _BadgePill(label: 'Cocina tradicional'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: _BentoRow(
                      left: _StatCard(
                        title: 'Rating',
                        value: '4.9',
                        icon: Icons.star,
                        tone: AppColors.secondary,
                      ),
                      right: _StatCard(
                        title: 'Platos servidos',
                        value: '500+',
                        icon: Icons.restaurant,
                        tone: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: _StoryCard(
                      title: 'Mi historia',
                      story: _asStory(cookName: cookName, bio: warmBio),
                      tags: const [
                        'Recetas tradicionales',
                        'Ingredientes locales',
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _SectionHeader(
                      title: 'Mis platos',
                      actionLabel: 'Ver menú',
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menú completo (próximamente).'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ...meals.when(
                  loading: () => const <Widget>[
                    SliverToBoxAdapter(child: _MealsPreviewLoading()),
                  ],
                  error: (e, _) => <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: _SoftErrorCard(
                          message: 'No pudimos cargar tus platos. $e',
                          onRetry: () => ref
                              .read(cookMealsControllerProvider.notifier)
                              .refresh(),
                        ),
                      ),
                    ),
                  ],
                  data: (items) {
                    if (items.isEmpty) {
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.lg,
                            ),
                            child: _SoftEmptyCard(
                              title: 'Todavía no hay platos publicados 🍲',
                              subtitle:
                                  'Publica tu primer plato y tu menú empieza a vivir.',
                              actionLabel: 'Publicar mi primer plato',
                              onAction: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ve a “Crear” para publicar tu primer plato.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ];
                    }

                    final picks = items.take(3).toList(growable: false);
                    return <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: picks.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: AppSpacing.lg),
                          itemBuilder: (context, i) =>
                              _MealPreviewCard(meal: picks[i]),
                        ),
                      ),
                    ];
                  },
                ),
                if (_editing)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      child: _EditCard(
                        saving: _saving,
                        businessName: _businessName,
                        bio: _bio,
                        onSave: _saving ? null : _saveProfile,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _saving
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                        child: const Text('Cerrar sesión'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CookProfileLoading extends StatelessWidget {
  const _CookProfileLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.35 : 0.55);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 360,
              decoration: BoxDecoration(
                color: base,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xl),
                  bottomRight: Radius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: 3,
              separatorBuilder: (context, _) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, _) => Container(
                height: 140,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _CookHero extends StatelessWidget {
  const _CookHero({
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    required this.saving,
    required this.onTapAvatar,
    required this.onToggleEdit,
    required this.editing,
  });

  final String? avatarUrl;
  final String name;
  final String subtitle;
  final bool saving;
  final VoidCallback? onTapAvatar;
  final VoidCallback onToggleEdit;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banner = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.18),
        AppColors.secondary.withValues(alpha: isDark ? 0.22 : 0.14),
        AppColors.bg,
      ],
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        topPad + AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: banner,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'CORRIENTAZO',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withValues(alpha: 0.92),
                ),
              ),
              const Spacer(),
              _HeroAction(
                label: editing ? 'Listo' : 'Editar',
                icon: editing ? Icons.check : Icons.edit_outlined,
                onTap: onToggleEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.0 : 0.14,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (avatarUrl ?? '').trim().isEmpty
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: AppColors.brand,
                            ),
                          )
                        : Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 64,
                                    color: AppColors.brand,
                                  ),
                                ),
                          ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.80),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Verificada',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.05,
              color: const Color(0xFF241913).withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: const Color(0xFF6B4A3A).withValues(alpha: 0.80),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            saving ? 'Guardando…' : 'Toca la foto para cambiarla',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.white.withValues(alpha: 0.70),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brand),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

class _BentoRow extends StatelessWidget {
  const _BentoRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: right),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.border).withValues(
            alpha: 0.80,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: tone.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: const Color(0xFF6B4A3A).withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.title,
    required this.story,
    required this.tags,
  });

  final String title;
  final String story;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.border).withValues(
            alpha: 0.80,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -16,
            child: Icon(
              Icons.soup_kitchen_outlined,
              size: 96,
              color: const Color(0xFF241913).withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '“$story”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        t,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary.withValues(alpha: 0.90),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealsPreviewLoading extends StatelessWidget {
  const _MealsPreviewLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.35 : 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: List.generate(
          2,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 1 ? 0 : AppSpacing.lg),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftErrorCard extends StatelessWidget {
  const _SoftErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftEmptyCard extends StatelessWidget {
  const _SoftEmptyCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _MealPreviewCard extends StatelessWidget {
  const _MealPreviewCard({required this.meal});
  final CookMeal meal;

  @override
  Widget build(BuildContext context) {
    final food = ColombianFoodMock.forMeal(meal.id);
    final title = meal.title.trim().isEmpty ? food.title : meal.title.trim();
    final desc = meal.description.trim().isEmpty
        ? 'Receta casera, servida con cariño.'
        : meal.description.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(
              CookCreateMealFormRoute.location(editMealId: meal.id),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.80),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: FoodImage(
                        asset: food.imageAsset,
                        fallbackGradient: food.heroGradient,
                        fallbackIcon: food.heroIcon,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(
                                  0xFF6B4A3A,
                                ).withValues(alpha: 0.74),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniPill(
                              label: 'COP ${meal.priceCop}',
                              tone: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _MiniPill(
                              label: meal.status == CookMealStatus.available
                                  ? 'Disponible'
                                  : meal.status == CookMealStatus.soldOut
                                  ? 'Agotado'
                                  : 'Pausado',
                              tone: meal.status == CookMealStatus.available
                                  ? AppColors.success
                                  : meal.status == CookMealStatus.soldOut
                                  ? AppColors.danger
                                  : AppColors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: tone.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({
    required this.saving,
    required this.businessName,
    required this.bio,
    required this.onSave,
  });

  final bool saving;
  final TextEditingController businessName;
  final TextEditingController bio;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: businessName,
            decoration: const InputDecoration(
              labelText: 'Nombre del negocio (o tu nombre)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: bio,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio corta (ej: “Sazón casera, porción generosa”)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              child: Text(saving ? 'Guardando…' : 'Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}

String _asStory({required String cookName, required String bio}) {
  final b = bio.trim();
  if (b.isEmpty) {
    return 'Cocino como me enseñaron en casa: con calma, porciones generosas '
        'y ese sabor que te hace sentir en familia.';
  }
  if (b.length > 220) return b.substring(0, 220);
  return b;
}
