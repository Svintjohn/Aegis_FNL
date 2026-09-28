import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'project_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final data = ref.watch(storeProvider);
    final isClient = role == Role.client;

// Client will see what projects they have posted, and freelancers will see what projects they are working on.
    final mine = data.projects.where((p) {
      if (isClient) return p.clientName == 'You' || p.freelancerName != null;
      return p.freelancerName != null;
    }).toList();

    final needsAction = mine.where((p) {
      final m = p.currentMilestone;
      if (m == null) return false;
      return isClient
          ? m.status == MilestoneStatus.submitted
          : m.status == MilestoneStatus.locked || m.status == MilestoneStatus.revision;
    }).toList();

    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 110),
        children: [
          _BalanceCard(isClient: isClient, projects: mine, wallet: data.walletBalance),
          const SizedBox(height: Gap.lg),
          if (needsAction.isNotEmpty) ...[
            SectionHeader(isClient ? 'Waiting on you' : 'Ready to work on'),
            for (final p in needsAction)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                child: ProjectCard(
                  project: p,
                  highlight: true,
                  onTap: () => context.push('/project/${p.id}'),
                ),
              ),
            const SizedBox(height: Gap.md),
          ],
          SectionHeader(isClient ? 'Your projects' : 'Your active work'),
          if (mine.isEmpty)
            EmptyState(
              icon: isClient ? Icons.post_add_rounded : Icons.work_outline_rounded,
              title: isClient ? 'No projects yet' : 'No active work yet',
              message: isClient
                  ? 'Post a project and lock the budget to get started.'
                  : 'Browse open jobs and send your first proposal.',
            )
          else
            for (final p in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                child: ProjectCard(
                  project: p,
                  onTap: () => context.push('/project/${p.id}'),
                ),
              ),
          const SizedBox(height: Gap.md),
          if (isClient) ...[
            SectionHeader('Top freelancers',
                action: 'See all', onAction: () => context.push('/browse-people')),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: demoFreelancers.length,
                separatorBuilder: (_, __) => const SizedBox(width: Gap.sm + 2),
                itemBuilder: (context, i) => _FreelancerTile(demoFreelancers[i]),
              ),
            ),
          ] else ...[
            SectionHeader('Open jobs for you',
                action: 'Browse all', onAction: () => context.push('/browse-jobs')),
            for (final p in data.projects.where((p) => p.freelancerName == null))
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                child: ProjectCard(
                  project: p,
                  asJobPost: true,
                  onTap: () => context.push('/project/${p.id}'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isClient;
  final List<Project> projects;
  final double wallet;

  const _BalanceCard({
    required this.isClient,
    required this.projects,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    final locked = projects.fold(0.0, (sum, p) => sum + p.lockedAmount);
    final active = projects.where((p) => p.status == ProjectStatus.active).length;
    final awaiting = projects
        .where((p) => p.currentMilestone?.status == MilestoneStatus.submitted)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClient
              ? const [AppColors.navy, AppColors.navyDeep]
              : const [AppColors.green, AppColors.greenDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isClient ? AppColors.navy : AppColors.green).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isClient ? 'Total funds locked' : 'Money locked for you',
                  style: AppText.caption.copyWith(color: Colors.white70)),
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 6),
          Text(peso(locked),
              style: AppText.display.copyWith(color: Colors.white, fontSize: 30)),
          const SizedBox(height: 4),
          Text(
            isClient
                ? 'Released only when you approve the work.'
                : 'Verified and secured before you start.',
            style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              _MiniStat(label: '$active active', icon: Icons.bolt_rounded),
              const SizedBox(width: Gap.sm),
              if (awaiting > 0)
                _MiniStat(
                    label: '$awaiting in review', icon: Icons.hourglass_top_rounded),
              if (!isClient) ...[
                const SizedBox(width: Gap.sm),
                _MiniStat(
                    label: '${peso(wallet)} available',
                    icon: Icons.account_balance_wallet_outlined),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniStat({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: AppText.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5)),
        ],
      ),
    );
  }
}

// A small card representing a freelancer in the horizontal list on the home screen.
class _FreelancerTile extends StatelessWidget {
  final AppUser user;
  const _FreelancerTile(this.user);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: AppCard(
        padding: const EdgeInsets.all(13),
        onTap: () => toast(context, '${user.name} — ${user.headline}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Avatar(user.name, radius: 21, verified: user.verified),
            const SizedBox(height: Gap.sm),
            Text(user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w700)),
            Text(user.headline,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                const SizedBox(width: 2),
                Text('${user.rating}', style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
