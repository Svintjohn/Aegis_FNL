import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Three steps: what the job is, how it's broken up, then confirm.
/// Split this way because the milestone step is where clients actually
/// think, and burying it under a long single form gets it skipped.
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _DraftMilestone {
  final TextEditingController title;
  final TextEditingController amount;
  _DraftMilestone([String t = '', String a = ''])
      : title = TextEditingController(text: t),
        amount = TextEditingController(text: a);

  double get value => double.tryParse(amount.text.replaceAll(',', '')) ?? 0;

  void dispose() {
    title.dispose();
    amount.dispose();
  }
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  int _step = 0;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _skills = <String>{'UI/UX Design'};
  final _milestones = [_DraftMilestone('Design & wireframes', '1500'), _DraftMilestone('Build & handover', '2500')];
  String? _error;

  static const _skillOptions = [
    'UI/UX Design', 'Figma', 'Flutter', 'React', 'Node.js',
    'Python', 'Illustration', 'Copywriting',
  ];

  double get _total => _milestones.fold(0.0, (sum, m) => sum + m.value);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  void _next() {
    setState(() {
      _error = switch (_step) {
        0 when _title.text.trim().isEmpty => 'Give the project a title',
        0 when _description.text.trim().length < 20 =>
          'Add a bit more detail so freelancers know what they are bidding on',
        1 when _milestones.any((m) => m.title.text.trim().isEmpty) =>
          'Every milestone needs a name',
        1 when _total <= 0 => 'Set an amount for each milestone',
        _ => null,
      };
    });
    if (_error != null) return;

    if (_step < 2) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _publish() {
    final id = ref.read(storeProvider.notifier).createProject(
          title: _title.text.trim(),
          description: _description.text.trim(),
          budget: _total,
          skills: _skills.toList(),
          milestones: [
            for (final m in _milestones) (title: m.title.text.trim(), amount: m.value),
          ],
        );

    toast(context, 'Project posted — lock the budget to start');
    context.pushReplacement('/project/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
        ),
        title: const Text('Post a project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
            child: _Steps(current: _step, labels: const ['Details', 'Milestones', 'Review']),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(key: ValueKey(_step), child: _body()),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.md),
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!,
                                style: AppText.caption.copyWith(color: AppColors.red)),
                          ),
                        ],
                      ),
                    ),
                  AppButton(
                    _step == 2 ? 'Post project' : 'Continue',
                    tone: _step == 2 ? ButtonTone.green : ButtonTone.navy,
                    icon: _step == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return switch (_step) {
      0 => ListView(
          padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
          children: [
            AppField(
              label: 'Project title',
              hint: 'e.g. Cafe POS System',
              controller: _title,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: Gap.md),
            AppField(
              label: 'What needs to be done?',
              hint: 'Describe the work, what "finished" looks like, and any '
                  'tools you need them to use.',
              controller: _description,
              maxLines: 5,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: Gap.md),
            Text('Skills needed',
                style: AppText.caption
                    .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final skill in _skillOptions)
                  Pressable(
                    scale: 0.94,
                    onTap: () => setState(() {
                      _skills.contains(skill) ? _skills.remove(skill) : _skills.add(skill);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _skills.contains(skill)
                            ? AppColors.navy
                            : AppColors.line.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        skill,
                        style: AppText.caption.copyWith(
                          color: _skills.contains(skill) ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      1 => ListView(
          padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
          children: [
            Text(
              'Split the work into chunks. Each one is funded upfront and '
              'released when you approve it.',
              style: AppText.caption,
            ),
            const SizedBox(height: Gap.md),
            for (var i = 0; i < _milestones.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm + 4),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                            child: Text('${i + 1}',
                                style: AppText.caption.copyWith(
                                    color: AppColors.navy, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: Gap.sm),
                          Expanded(
                            child: Text('Milestone ${i + 1}',
                                style: AppText.title.copyWith(fontSize: 14)),
                          ),
                          if (_milestones.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.muted),
                              onPressed: () => setState(() {
                                _milestones.removeAt(i).dispose();
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      AppField(
                        label: '',
                        hint: 'What gets delivered?',
                        controller: _milestones[i].title,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: Gap.sm),
                      AppField(
                        label: '',
                        hint: 'Amount in ₱',
                        icon: Icons.payments_outlined,
                        controller: _milestones[i].amount,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            if (_milestones.length < 5)
              AppButton(
                'Add milestone',
                tone: ButtonTone.outline,
                icon: Icons.add_rounded,
                onPressed: () => setState(() => _milestones.add(_DraftMilestone())),
              ),
            const SizedBox(height: Gap.md),
            AppCard(
              child: Row(
                children: [
                  Text('Total budget', style: AppText.title.copyWith(fontSize: 14)),
                  const Spacer(),
                  Text(peso(_total),
                      style: AppText.heading.copyWith(color: AppColors.green)),
                ],
              ),
            ),
          ],
        ),
      _ => ListView(
          padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title.text, style: AppText.heading.copyWith(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(_description.text, style: AppText.body),
                  const SizedBox(height: Gap.sm + 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in _skills) SkillChip(s)],
                  ),
                  const Divider(height: Gap.lg + 6),
                  for (var i = 0; i < _milestones.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${i + 1}. ${_milestones[i].title.text}',
                                style: AppText.caption),
                          ),
                          Text(peso(_milestones[i].value),
                              style: AppText.caption.copyWith(
                                  color: AppColors.ink, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const Divider(height: Gap.lg),
                  Row(
                    children: [
                      Text('Total to lock', style: AppText.title.copyWith(fontSize: 14)),
                      const Spacer(),
                      Text(peso(_total),
                          style: AppText.heading.copyWith(color: AppColors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.amber),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Posting is free. The budget is only locked once you deposit '
                      'it on the next screen.',
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    };
  }
}

class _Steps extends StatelessWidget {
  final int current;
  final List<String> labels;

  const _Steps({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.navy : AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: AppText.caption.copyWith(
                    fontSize: 11.5,
                    color: i <= current ? AppColors.navy : AppColors.muted,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}
