import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'browse_screen.dart';
import 'chat_screens.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int _tab = 0;

  static const _tabs = [
    (Icons.home_rounded, 'Home'),
    (Icons.search_rounded, 'Browse'),
    (Icons.chat_bubble_rounded, 'Chats'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
    final unread = ref.watch(storeProvider).unreadNotices;

    final pages = [
      const HomeScreen(),
      const BrowseScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_tabs[_tab].$2),
            const SizedBox(width: 8),
            _RoleToggle(role: role),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (unread > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$unread',
                        style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      endDrawer: const _Menu(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      floatingActionButton: _tab == 0 && role == Role.client
          ? Padding(
              padding: const EdgeInsets.only(bottom: 68),
              child: Pressable(
                onTap: () => context.push('/post'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.greenGradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 19),
                      const SizedBox(width: 6),
                      Text('Post project',
                          style: AppText.title.copyWith(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _NavBar(
        index: _tab,
        items: _tabs,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _RoleToggle extends ConsumerWidget {
  final Role role;
  const _RoleToggle({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClient = role == Role.client;
    return Pressable(
      onTap: () {
        ref.read(roleProvider.notifier).state = isClient ? Role.freelancer : Role.client;
        toast(context, 'Switched to ${isClient ? 'Freelancer' : 'Client'} view');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (isClient ? AppColors.navy : AppColors.green).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isClient ? 'Client' : 'Freelancer',
              style: AppText.caption.copyWith(
                color: isClient ? AppColors.navy : AppColors.greenDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded,
                size: 14, color: isClient ? AppColors.navy : AppColors.greenDeep),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final ValueChanged<int> onTap;

  const _NavBar({required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.sm + 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.navy.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(items[i].$1,
                          size: 21,
                          color: i == index ? AppColors.navy : AppColors.muted),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: i == index
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(items[i].$2,
                                    style: AppText.caption.copyWith(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w700)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openCases = ref.watch(storeProvider).cases.where((c) => !c.resolved).length;

    final links = <(IconData, String, String, String?)>[
      (Icons.account_balance_wallet_outlined, 'Wallet & withdraw', '/wallet', null),
      (Icons.verified_user_outlined, 'Verification', '/verification', null),
      (
        Icons.gavel_rounded,
        'Admin cases',
        '/admin',
        openCases > 0 ? '$openCases open' : null
      ),
      (Icons.settings_outlined, 'Settings', '/settings', null),
    ];

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.md + 2, Gap.lg, Gap.md, Gap.md),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.navyGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aegis', style: AppText.heading),
                      Text('John Benedict Berceles', style: AppText.caption),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            for (final (icon, label, route, badge) in links)
              ListTile(
                leading: Icon(icon, color: AppColors.ink, size: 21),
                title: Text(label, style: AppText.body),
                trailing: badge == null
                    ? const Icon(Icons.chevron_right_rounded, color: AppColors.muted)
                    : StatusPill(badge, color: AppColors.red),
                onTap: () {
                  Navigator.pop(context);
                  context.push(route);
                },
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.red, size: 21),
              title: Text('Log out', style: AppText.body.copyWith(color: AppColors.red)),
              onTap: () => context.go('/login'),
            ),
            const SizedBox(height: Gap.sm),
          ],
        ),
      ),
    );
  }
}