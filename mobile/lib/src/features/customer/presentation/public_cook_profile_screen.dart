import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/marketplace/meal_card_premium.dart';
import '../../meals/application/meals_controller.dart';
import '../../meals/domain/meal_publication.dart';

class PublicCookProfileScreen extends ConsumerWidget {
  const PublicCookProfileScreen({super.key, required this.cookProfileId});

  final String cookProfileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);

    void goBack() {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(const CustomerHomeRoute().location);
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: feed.when(
          loading: () => const _PublicCookLoading(),
          error: (e, _) => _PublicCookError(
            message: e.toString(),
            onRetry: () => ref.read(mealsFeedProvider.notifier).refresh(),
          ),
          data: (items) {
            try {
              final cookMeals = items
                  .where((m) => m.cookProfileId == cookProfileId)
                  .toList();
              if (cookMeals.isEmpty) {
                return _PublicCookEmpty(
                  onGoHome: () =>
                      context.go(const CustomerHomeRoute().location),
                );
              }

              final hero = cookMeals.first;
              final cookName = (hero.cookName ?? 'Cocina del barrio').trim();
              final cookBio = (hero.cookBio ?? '').trim().isEmpty
                  ? 'Cocinando sabores caseros con cariño, como en casa. 🍲'
                  : (hero.cookBio ?? '').trim();
              final avatarUrl = (hero.cookAvatarUrl ?? '').trim();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _CookHero(
                      cookName: cookName,
                      cookBio: cookBio,
                      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
                      onBack: goBack,
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
                      child: _StoryCard(
                        title: 'Sobre este cook',
                        story: _asStory(cookName: cookName, bio: cookBio),
                        tags: const ['Recetas de casa', 'Ingredientes locales'],
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
                        title: 'Platos de hoy',
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: cookMeals.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, i) {
                        final m = cookMeals[i];
                        return MealCardPremium(
                          key: ValueKey('cook-$cookProfileId-${m.id}'),
                          id: m.id,
                          mealId: m.mealId,
                          priceCop: m.priceCop,
                          stockAvailable: m.stockAvailable,
                          title: m.title,
                          description: m.description,
                          tags: m.tags,
                          photoUrl: m.photoUrl,
                          cookName: m.cookName,
                          cookAvatarUrl: m.cookAvatarUrl,
                          cookBio: m.cookBio,
                          fulfillmentLabel: m.fulfillmentCustomerLabel,
                          onTap: () => context.push(
                            '${const HomeRoute().location}/meals/${m.id}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } catch (e) {
              return _PublicCookError(
                message: 'Error dibujando el perfil. ($e)',
                onRetry: () => ref.read(mealsFeedProvider.notifier).refresh(),
              );
            }
          },
        ),
      ),
    );
  }
}

class _CookHero extends StatelessWidget {
  const _CookHero({
    required this.cookName,
    required this.cookBio,
    required this.avatarUrl,
    required this.onBack,
  });

  final String cookName;
  final String cookBio;
  final String? avatarUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = (avatarUrl ?? '').trim();
    final banner = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary.withValues(alpha: isDark ? 0.26 : 0.18),
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
              _OverlayIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const Spacer(),
              Text(
                'CORRIENTAZO',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withValues(alpha: 0.90),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 44, height: 44),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Stack(
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
                  child: avatar.isEmpty
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
                          avatar,
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
                      const Icon(Icons.verified, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Verificado',
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            cookName,
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
            cookBio,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PrimaryCta(
                label: 'Ver platos',
                onTap: () {
                  // Scroll is the CTA; keep it calm.
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.white.withValues(alpha: 0.70),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 18, color: AppColors.brand),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Defensive constraints: some FilledButton themes apply infinite minWidth.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.92),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            minimumSize: Size.zero,
            elevation: 0,
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
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

class _PublicCookLoading extends StatelessWidget {
  const _PublicCookLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.35 : 0.55);

    return CustomScrollView(
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
            itemCount: 2,
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
    );
  }
}

class _PublicCookError extends StatelessWidget {
  const _PublicCookError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No pudimos cargar este perfil',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicCookEmpty extends StatelessWidget {
  const _PublicCookEmpty({required this.onGoHome});
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Este cook no tiene platos publicados hoy 🍲',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve al marketplace y mira qué está cocinando el barrio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B4A3A).withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onGoHome,
              child: const Text('Ver platos de hoy'),
            ),
          ],
        ),
      ),
    );
  }
}

String _asStory({required String cookName, required String bio}) {
  final b = bio.trim();
  if (b.isEmpty) {
    return '$cookName cocina como en casa: con calma, con cariño y porciones '
        'honestas. Cada plato busca que tu almuerzo se sienta humano.';
  }
  if (b.length > 220) return b.substring(0, 220);
  if (b.length <= 120) {
    return 'Cocino así porque creo en el sabor de hogar: $b';
  }
  return b;
}
