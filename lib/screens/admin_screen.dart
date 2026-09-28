import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Where a case lands when the app's own rules can't settle it. Kept
/// deliberately plain — an admin needs the facts and three buttons.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(storeProvider).cases;
    final open = cases.where((c) => !c.resolved).toList();
    final closed = cases.where((c) => c.resolved).toList();

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Admin cases')),
      body: cases.isEmpty
          ? const EmptyState(
              icon: Icons.gavel_rounded,
              title: 'No open cases',
              message: 'Cases appear here when someone requests a human review.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 32),
              children: [
                if (open.isNotEmpty) ...[
                  SectionHeader('Needs a decision'),
                  for (final c in open)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                      child: AppCard(
                        border: AppColors.red.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(c.projectTitle, style: AppText.title)),
                                StatusPill('Open', color: AppColors.red),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Raised by ${c.raisedBy} · ${timeAgo(c.openedAt)}',
                                style: AppText.caption),
                            const SizedBox(height: Gap.sm + 2),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(c.reason, style: AppText.caption),
                            ),
                            const SizedBox(height: Gap.md),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    'Resolve',
                                    tone: ButtonTone.green,
                                    onPressed: () {
                                      ref.read(storeProvider.notifier).resolveCase(c.id);
                                      toast(context, 'Case closed — funds unfrozen',
                                          good: true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: Gap.sm),
                                AppButton(
                                  'Open project',
                                  fullWidth: false,
                                  tone: ButtonTone.outline,
                                  onPressed: () => context.push('/project/${c.projectId}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: Gap.md),
                ],
                if (closed.isNotEmpty) ...[
                  SectionHeader('Closed'),
                  for (final c in closed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 19, color: AppColors.green),
                            const SizedBox(width: Gap.sm + 2),
                            Expanded(
                              child: Text(c.projectTitle,
                                  style: AppText.body.copyWith(color: AppColors.muted)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
