import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProjectScreen extends ConsumerWidget {
  final String projectId;
  const ProjectScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(storeProvider).project(projectId);
    final role = ref.watch(roleProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Project not found',
          message: 'It may have been removed.',
        ),
      );
    }

    final isClient = role == Role.client;
    final unassigned = project.freelancerName == null;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(project.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (!unassigned)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Open chat',
              onPressed: () => context.push('/chat/${project.id}'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 32),
        children: [
          _EscrowBanner(project: project),
          const SizedBox(height: Gap.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About this project', style: AppText.title),
                const SizedBox(height: 6),
                Text(project.description, style: AppText.body),
                const SizedBox(height: Gap.sm + 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final s in project.skills) SkillChip(s)],
                ),
                const Divider(height: Gap.lg + 4),
                Row(
                  children: [
                    Avatar(project.clientName, radius: 17),
                    const SizedBox(width: Gap.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.clientName, style: AppText.title.copyWith(fontSize: 14)),
                          Text('Client · posted ${timeAgo(project.postedAt)}',
                              style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                if (project.freelancerName != null) ...[
                  const SizedBox(height: Gap.sm + 4),
                  Row(
                    children: [
                      Avatar(project.freelancerName!, radius: 17, verified: true),
                      const SizedBox(width: Gap.sm + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(project.freelancerName!,
                                style: AppText.title.copyWith(fontSize: 14)),
                            Text('Freelancer', style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          if (unassigned && !isClient) ...[
            AppButton(
              'Send a proposal',
              icon: Icons.send_rounded,
              onPressed: () {
                ref.read(storeProvider.notifier).applyToProject(project.id);
                toast(context, 'Proposal sent to ${project.clientName}', good: true);
              },
            ),
            const SizedBox(height: Gap.lg),
          ],
          SectionHeader('Milestones'),
          _Timeline(project: project, isClient: isClient),
          const SizedBox(height: Gap.lg),
          if (!unassigned && project.status != ProjectStatus.disputed)
            Center(
              child: Pressable(
                onTap: () => _escalate(context, ref, project),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.red, width: 1.4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_outlined, size: 16, color: AppColors.red),
                      const SizedBox(width: 6),
                      Text('Request admin review',
                          style: AppText.caption.copyWith(
                              color: AppColors.red, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _escalate(BuildContext context, WidgetRef ref, Project project) async {
    final reason = await _promptForText(
      context,
      title: 'Request admin review',
      helper: 'Tell us what went wrong. Funds stay frozen until an admin responds.',
      hint: 'e.g. The delivered work does not match what we agreed on.',
      action: 'Open case',
      danger: true,
    );
    if (reason == null || !context.mounted) return;

    ref.read(storeProvider.notifier).openCase(project.id, reason);
    toast(context, 'Case opened — an admin will review this project');
  }
}

class _EscrowBanner extends ConsumerWidget {
  final Project project;
  const _EscrowBanner({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClient = ref.watch(roleProvider) == Role.client;

    if (project.status == ProjectStatus.disputed) {
      return _Banner(
        color: AppColors.red,
        icon: Icons.gavel_rounded,
        title: 'Under admin review',
        body: 'Funds are frozen while an admin looks into this project.',
      );
    }

    if (!project.isFunded) {
      return Column(
        children: [
          _Banner(
            color: AppColors.amber,
            icon: Icons.lock_open_rounded,
            title: 'Budget not locked yet',
            body: isClient
                ? 'Deposit ${peso(project.budget)} to start the contract.'
                : "The client hasn't funded this project yet.",
          ),
          if (isClient && project.clientName == 'You') ...[
            const SizedBox(height: Gap.sm + 4),
            AppButton(
              'Deposit ${peso(project.budget)}',
              tone: ButtonTone.green,
              icon: Icons.lock_outline_rounded,
              onPressed: () => context.push('/deposit/${project.id}'),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.greenDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Money locked in escrow',
                    style: AppText.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(peso(project.lockedAmount),
                    style: AppText.display.copyWith(color: Colors.white, fontSize: 26)),
                if (project.releasedAmount > 0)
                  Text('${peso(project.releasedAmount)} already released',
                      style: AppText.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Gap.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title.copyWith(fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(body, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  final Project project;
  final bool isClient;

  const _Timeline({required this.project, required this.isClient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frozen = project.status == ProjectStatus.disputed;

    return Column(
      children: [
        for (var i = 0; i < project.milestones.length; i++)
          _TimelineRow(
            milestone: project.milestones[i],
            isLast: i == project.milestones.length - 1,
            project: project,
            isClient: isClient,
            frozen: frozen || !project.isFunded,
          ),
      ],
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  final Milestone milestone;
  final bool isLast;
  final Project project;
  final bool isClient;
  final bool frozen;

  const _TimelineRow({
    required this.milestone,
    required this.isLast,
    required this.project,
    required this.isClient,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = milestone.status == MilestoneStatus.released;
    final isCurrent = project.currentMilestone?.id == milestone.id;

    final (dotColor, dotIcon) = switch (milestone.status) {
      MilestoneStatus.released => (AppColors.green, Icons.check_rounded),
      MilestoneStatus.submitted => (AppColors.navy, Icons.hourglass_top_rounded),
      MilestoneStatus.revision => (AppColors.amber, Icons.refresh_rounded),
      MilestoneStatus.locked =>
        isCurrent ? (AppColors.navy, Icons.play_arrow_rounded) : (AppColors.line, Icons.lock_outline),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                child: Icon(dotIcon,
                    size: 15,
                    color: dotColor == AppColors.line ? AppColors.muted : Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.green.withValues(alpha: 0.4) : AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Gap.sm + 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Gap.md + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(milestone.title, style: AppText.title.copyWith(fontSize: 14.5))),
                      Text(peso(milestone.amount),
                          style: AppText.title.copyWith(
                              fontSize: 14, color: done ? AppColors.green : AppColors.ink)),
                    ],
                  ),
                  Text('${milestone.percent}% of budget', style: AppText.caption),
                  if (milestone.submissionNote != null &&
                      milestone.status != MilestoneStatus.released) ...[
                    const SizedBox(height: Gap.sm),
                    _Note(
                      label: 'Submitted',
                      text: milestone.submissionNote!,
                      color: AppColors.navy,
                    ),
                  ],
                  if (milestone.revisionNote != null &&
                      milestone.status == MilestoneStatus.revision) ...[
                    const SizedBox(height: Gap.sm),
                    _Note(
                      label: 'Changes requested',
                      text: milestone.revisionNote!,
                      color: AppColors.amber,
                    ),
                  ],
                  if (milestone.daysLeftToReview != null) ...[
                    const SizedBox(height: Gap.sm),
                    StatusPill(
                      '${milestone.daysLeftToReview} days left to review',
                      color: milestone.daysLeftToReview! <= 3
                          ? AppColors.red
                          : AppColors.amber,
                      icon: Icons.timer_outlined,
                    ),
                  ],
                  if (isCurrent && !frozen) ...[
                    const SizedBox(height: Gap.sm + 4),
                    _actions(context, ref),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref) {
    final store = ref.read(storeProvider.notifier);

    // Freelancer side: submit work, or resubmit after a revision request.
    if (!isClient) {
      if (milestone.status == MilestoneStatus.submitted) {
        return Text('Waiting for the client to review.',
            style: AppText.caption.copyWith(fontStyle: FontStyle.italic));
      }
      return AppButton(
        milestone.status == MilestoneStatus.revision ? 'Resubmit work' : 'Submit work',
        icon: Icons.upload_rounded,
        onPressed: () async {
          final note = await _promptForText(
            context,
            title: 'Submit ${milestone.title}',
            helper: 'Add a short note or a link to the files.',
            hint: 'e.g. Uploaded to Drive — link in chat.',
            action: 'Submit',
          );
          if (note == null || !context.mounted) return;
          store.submitWork(project.id, milestone.id, note);
          toast(context, 'Work submitted — the 14-day review timer started', good: true);
        },
      );
    }

    // Client side: approve (money moves) or send it back.
    if (milestone.status != MilestoneStatus.submitted) {
      return Text(
        milestone.status == MilestoneStatus.revision
            ? 'Waiting for the freelancer to resubmit.'
            : 'Waiting for the freelancer to submit this milestone.',
        style: AppText.caption.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            'Approve & release',
            tone: ButtonTone.green,
            onPressed: () => _confirmRelease(context, store),
          ),
        ),
        const SizedBox(width: Gap.sm),
        AppButton(
          'Revise',
          fullWidth: false,
          tone: ButtonTone.outline,
          onPressed: () async {
            final note = await _promptForText(
              context,
              title: 'Request changes',
              helper: 'Be specific — this is what the freelancer will work from.',
              hint: 'e.g. The totals row should show tax separately.',
              action: 'Send back',
            );
            if (note == null || !context.mounted) return;
            store.requestRevision(project.id, milestone.id, note);
            toast(context, 'Revision request sent');
          },
        ),
      ],
    );
  }

  Future<void> _confirmRelease(BuildContext context, Store store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Release ${peso(milestone.amount)}?', style: AppText.heading.copyWith(fontSize: 18)),
        content: Text(
          'This pays out ${milestone.title} and cannot be undone.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Release funds'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    store.releaseMilestone(project.id, milestone.id);
    toast(context, '${peso(milestone.amount)} released', good: true);
  }
}

class _Note extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _Note({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(text, style: AppText.caption.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Shared bottom sheet for "type a note, then confirm" — submitting work,
/// requesting a revision, and opening a case all use the same shape.
Future<String?> _promptForText(
  BuildContext context, {
  required String title,
  required String helper,
  required String hint,
  required String action,
  bool danger = false,
}) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
          Gap.lg, Gap.md, Gap.lg, MediaQuery.of(context).viewInsets.bottom + Gap.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: Gap.md + 4),
          Text(title, style: AppText.heading),
          const SizedBox(height: 4),
          Text(helper, style: AppText.caption),
          const SizedBox(height: Gap.md),
          AppField(label: '', hint: hint, controller: controller, maxLines: 4),
          const SizedBox(height: Gap.md),
          AppButton(
            action,
            tone: danger ? ButtonTone.danger : ButtonTone.navy,
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isEmpty ? '(no note added)' : text);
            },
          ),
          const SizedBox(height: Gap.sm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppText.caption.copyWith(color: AppColors.muted)),
            ),
          ),
        ],
      ),
    ),
  );
}
