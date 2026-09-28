import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

// This represent project for the home screen, browse screen, and search results. It is not used for the project details screen.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final bool asJobPost;
  final bool highlight;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.asJobPost = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = project.currentMilestone;
    final (label, color) = _status(project, milestone);

    return AppCard(
      onTap: onTap,
      border: highlight ? color.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(project.title, style: AppText.title)),
              const SizedBox(width: Gap.sm),
              StatusPill(label, color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            asJobPost ? project.description : project.clientName,
            maxLines: asJobPost ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
          const SizedBox(height: Gap.sm + 2),
          if (asJobPost) ...[
            Row(
              children: [
                Text(peso(project.budget),
                    style: AppText.title.copyWith(color: AppColors.green, fontSize: 14.5)),
                const Spacer(),
                Text('${project.proposals} proposals · ${timeAgo(project.postedAt)}',
                    style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
            if (project.skills.isNotEmpty) ...[
              const SizedBox(height: Gap.sm + 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final s in project.skills) SkillChip(s)],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Text('${peso(project.lockedAmount)} locked',
                    style: AppText.caption
                        .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${project.milestones.where((m) => m.status == MilestoneStatus.released).length}'
                  '/${project.milestones.length} milestones',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: project.progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.line,
                  color: AppColors.green,
                ),
              ),
            ),
            if (milestone?.daysLeftToReview != null) ...[
              const SizedBox(height: Gap.sm + 2),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14,
                      color: milestone!.daysLeftToReview! <= 3
                          ? AppColors.red
                          : AppColors.amber),
                  const SizedBox(width: 5),
                  Text(
                    '${milestone.daysLeftToReview} days left to review',
                    style: AppText.caption.copyWith(
                      color: milestone.daysLeftToReview! <= 3
                          ? AppColors.red
                          : AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  (String, Color) _status(Project p, Milestone? m) {
    if (p.status == ProjectStatus.disputed) return ('Under review', AppColors.red);
    if (p.status == ProjectStatus.completed) return ('Completed', AppColors.green);
    if (p.status == ProjectStatus.awaitingFunds) {
      return (asJobPost ? 'Open' : 'Awaiting funds', AppColors.amber);
    }
    return switch (m?.status) {
      MilestoneStatus.submitted => ('In review', AppColors.navy),
      MilestoneStatus.revision => ('Revision', AppColors.amber),
      _ => ('In progress', AppColors.green),
    };
  }
}
