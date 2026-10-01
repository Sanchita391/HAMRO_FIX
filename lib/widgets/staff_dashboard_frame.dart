import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hamro_fix/core/l10n/app_locale.dart';
import 'package:hamro_fix/core/theme/app_theme.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';
import 'package:hamro_fix/screens/dashboards/dashboard_widgets.dart';

bool staffUsesSidebar(BuildContext context) {
  return kIsWeb && MediaQuery.sizeOf(context).width >= 880;
}

class StaffNavItem {
  const StaffNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

// Desktop: green sidebar + wide content. Narrower browser: bottom bar.
class StaffDashboardFrame extends StatelessWidget {
  const StaffDashboardFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.body,
    required this.onLogout,
    this.photoUrl,
  });

  final String title;
  final String subtitle;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<StaffNavItem> items;
  final Widget body;
  final VoidCallback onLogout;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final sidebar = staffUsesSidebar(context);
    if (!sidebar) {
      return Scaffold(
        backgroundColor: HamroFixTheme.canvas,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: HamroFixBarTitle(
            title: title,
            subtitle: subtitle,
            photoUrl: photoUrl,
          ),
          actions: [
            TextButton(onPressed: onLogout, child: const Text('Log out')),
          ],
        ),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          indicatorColor: const Color(0xFFC8E6C9),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF4EE),
      body: Row(
        children: [
          _StaffSideMenu(
            title: title,
            subtitle: subtitle,
            selectedIndex: selectedIndex,
            items: items,
            onSelect: onSelect,
            onLogout: onLogout,
          ),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 0,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD7E3D7)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const HamroFixLogoBadge(size: 32, padding: 6),
                        const SizedBox(width: 12),
                        const Text(
                          'HamroFix',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A3D1A),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          height: 28,
                          color: const Color(0xFFD7E3D7),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          items[selectedIndex].label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A3D1A),
                          ),
                        ),
                        const Spacer(),
                        const LanguageToggle(),
                        const SizedBox(width: 12),
                        UserPhotoAvatar(
                          url: photoUrl,
                          name: subtitle,
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: body,
                      ),
                    ),
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

class _StaffSideMenu extends StatelessWidget {
  const _StaffSideMenu({
    required this.title,
    required this.subtitle,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final int selectedIndex;
  final List<StaffNavItem> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: HamroFixTheme.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                const HamroFixLogoBadge(
                  size: 40,
                  padding: 8,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HamroFix',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Ward desk',
                        style: TextStyle(color: Color(0xFFB8D8B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFB8D8B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            _SideNavButton(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton(
              onPressed: onLogout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final StaffNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? HamroFixTheme.darkGreen : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? const Color(0xFFC8E6C9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 22),
                  child: selected ? item.selectedIcon : item.icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
