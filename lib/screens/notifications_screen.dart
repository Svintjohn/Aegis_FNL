import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(storeProvider).notices;
    final unread = notices.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {
                ref.read(storeProvider.notifier).markAllNoticesRead();
                toast(context, 'All caught up');
              },
              child: Text('Mark all read',
                  style: AppText.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: notices.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing here yet',
              message: 'Timer warnings and payment updates will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 32),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: Gap.sm + 2),
              itemBuilder: (context, i) => _NoticeTile(notice: notices[i]),
            ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final Notice notice;
  const _NoticeTile({required this.notice});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notice.kind) {
      NoticeKind.timer => (Icons.timer_outlined, AppColors.red),
      NoticeKind.payment => (Icons.payments_outlined, AppColors.green),
      NoticeKind.message => (Icons.chat_bubble_outline_rounded, AppColors.navy),
      NoticeKind.verification => (Icons.verified_outlined, AppColors.green),
      NoticeKind.admin => (Icons.gavel_rounded, AppColors.amber),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: notice.projectId == null
          ? null
          : () => context.push('/project/${notice.projectId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: Gap.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(notice.title,
                            style: AppText.title.copyWith(fontSize: 14))),
                    if (!notice.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.navy, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(notice.body, style: AppText.caption),
                const SizedBox(height: 4),
                Text(timeAgo(notice.at),
                    style: AppText.caption.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
