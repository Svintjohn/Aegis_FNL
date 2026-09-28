import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'project_card.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  /// Opens straight to one tab when pushed from a se all link.
  final int initialTab;
  final bool standalone;

  const BrowseScreen({super.key, this.initialTab = 0, this.standalone = false});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late int _tab = widget.initialTab;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(storeProvider);
    final q = _query.toLowerCase();

    final jobs = data.projects
        .where((p) => p.freelancerName == null)
        .where((p) =>
            q.isEmpty ||
            p.title.toLowerCase().contains(q) ||
            p.skills.any((s) => s.toLowerCase().contains(q)))
        .toList();

    final people = demoFreelancers
        .where((u) =>
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.headline.toLowerCase().contains(q) ||
            u.skills.any((s) => s.toLowerCase().contains(q)))
        .toList();

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.sm + 4),
          child: AppField(
            label: '',
            hint: 'Search projects or people',
            icon: Icons.search_rounded,
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: _Segmented(
            labels: const ['Projects', 'Freelancers'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: _tab == 0
              ? (jobs.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No projects found',
                      message: 'Try a different keyword or clear the search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          Gap.md, Gap.md, Gap.md, 110),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Gap.sm + 2),
                      itemBuilder: (context, i) => ProjectCard(
                        project: jobs[i],
                        asJobPost: true,
                        onTap: () => context.push('/project/${jobs[i].id}'),
                      ),
                    ))
              : (people.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'No freelancers found',
                      message: 'Try a different skill or name.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          Gap.md, Gap.md, Gap.md, 110),
                      itemCount: people.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Gap.sm + 2),
                      itemBuilder: (context, i) => _PersonCard(people[i]),
                    )),
        ),
      ],
    );

    if (!widget.standalone) return body;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_tab == 0 ? 'Browse projects' : 'Browse freelancers'),
      ),
      body: body,
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == index
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: AppText.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == index ? AppColors.navy : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final AppUser user;
  const _PersonCard(this.user);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(user.name, radius: 24, verified: user.verified),
              const SizedBox(width: Gap.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppText.title),
                    Text(user.headline, style: AppText.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text('${user.rating}',
                          style: AppText.caption.copyWith(
                              color: AppColors.ink, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Text('${user.completedProjects} projects', style: AppText.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gap.sm + 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final s in user.skills) SkillChip(s)],
          ),
          const SizedBox(height: Gap.sm + 4),
          Row(
            children: [
              Text(user.rate,
                  style: AppText.caption.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w700)),
              const Spacer(),
              AppButton(
                'Invite',
                fullWidth: false,
                tone: ButtonTone.outline,
                onPressed: () => toast(context, 'Invite sent to ${user.name}', good: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
