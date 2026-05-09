import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_radius.dart';
import '../../design/tokens/app_spacing.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _goBranch,
        items: const [
          _NavItem(
            label: 'Hoy',
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant,
          ),
          _NavItem(
            label: 'Pedidos',
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag,
          ),
          _NavItem(
            label: 'Perfil',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ],
      ),
    );
  }
}

class CookShell extends StatelessWidget {
  const CookShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _goBranch,
        items: const [
          _NavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
          ),
          _NavItem(
            label: 'Platos',
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
          ),
          _NavItem(
            label: 'Crear',
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle,
          ),
          _NavItem(
            label: 'Pedidos',
            icon: Icons.inbox_outlined,
            activeIcon: Icons.inbox,
          ),
          _NavItem(
            label: 'Perfil',
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.currentIndex,
    required this.onSelect,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.92 : 0.94);
    final border = (isDark ? AppColors.borderDark : AppColors.border)
        .withValues(alpha: 0.75);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.08),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _BottomNavItem(
                    label: items[i].label,
                    icon: items[i].icon,
                    activeIcon: items[i].activeIcon,
                    active: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
                if (i != items.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = AppColors.secondary.withValues(alpha: 0.92);
    final inactiveFg = const Color(
      0xFF6B4A3A,
    ).withValues(alpha: isDark ? 0.66 : 0.72);

    final bg = widget.active ? activeBg : Colors.transparent;
    final fg = widget.active ? AppColors.bg : inactiveFg;

    final scale = _pressed ? 0.98 : 1.0;
    final contentOpacity = widget.active ? 1.0 : 0.92;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: widget.active && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white.withValues(
            alpha: widget.active ? 0.10 : 0.06,
          ),
          highlightColor: Colors.white.withValues(
            alpha: widget.active ? 0.06 : 0.04,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            opacity: contentOpacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.active ? widget.activeIcon : widget.icon,
                  size: 22,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                      color: fg,
                    ),
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
