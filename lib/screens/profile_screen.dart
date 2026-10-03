import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final data = ref.watch(storeProvider);
    final completed =
        data.projects.where((p) => p.status == ProjectStatus.completed).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.md, 110),
      children: [
        Column(
          children: [
            const Avatar('John Benedict Berceles', radius: 40, verified: true),
            const SizedBox(height: Gap.sm + 4),
            Text('John Benedict Berceles', style: AppText.heading),
            const SizedBox(height: 2),
            Text(
              role == Role.client ? 'Client · Angeles City' : 'Freelancer · UI/UX Designer',
              style: AppText.caption,
            ),
            const SizedBox(height: Gap.sm + 2),
            StatusPill('Verified student', color: AppColors.green, icon: Icons.verified),
          ],
        ),
        const SizedBox(height: Gap.lg + 4),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(value: '4.9', label: 'Rating'),
              _divider(),
              _Stat(value: '$completed', label: 'Completed'),
              _divider(),
              _Stat(value: peso(data.walletBalance), label: 'Available'),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        SectionHeader('Account'),
        _Tile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Wallet & withdraw',
          onTap: () => context.push('/wallet'),
        ),
        _Tile(
          icon: Icons.verified_user_outlined,
          label: 'Verification',
          trailing: StatusPill('Verified', color: AppColors.green),
          onTap: () => context.push('/verification'),
        ),
        _Tile(
          icon: Icons.star_outline_rounded,
          label: 'Ratings & reviews',
          onTap: () => toast(context, 'Reviews open once a project is completed'),
        ),
        _Tile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: Gap.md),
        AppButton(
          'Log out',
          tone: ButtonTone.outline,
          icon: Icons.logout_rounded,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.line);
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.heading.copyWith(fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption.copyWith(fontSize: 11.5)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: Gap.md),
            Expanded(child: Text(label, style: AppText.body)),
            trailing ??
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _documents = <String, bool>{
    'School ID': true,
    'Government ID': true,
    'Proof of enrollment': false,
  };

  @override
  Widget build(BuildContext context) {
    final done = _documents.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Verification')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                Icon(
                  done == _documents.length
                      ? Icons.verified_rounded
                      : Icons.pending_outlined,
                  size: 42,
                  color: done == _documents.length ? AppColors.green : AppColors.amber,
                ),
                const SizedBox(height: Gap.sm + 2),
                Text(
                  done == _documents.length ? 'Fully verified' : 'Partly verified',
                  style: AppText.heading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done of ${_documents.length} documents approved',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            'Verified freelancers get a badge on their profile, which clients '
            'filter by when there is no work history to go on yet.',
            style: AppText.caption,
          ),
          const SizedBox(height: Gap.md),
          for (final entry in _documents.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.upload_file_outlined,
                      size: 20,
                      color: entry.value ? AppColors.green : AppColors.muted,
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(child: Text(entry.key, style: AppText.body)),
                    if (entry.value)
                      StatusPill('Approved', color: AppColors.green)
                    else
                      AppButton(
                        'Upload',
                        fullWidth: false,
                        tone: ButtonTone.outline,
                        onPressed: () {
                          setState(() => _documents[entry.key] = true);
                          toast(context, '${entry.key} submitted for review', good: true);
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _toggles = <String, bool>{
    'Milestone updates': true,
    'Review deadline reminders': true,
    'New messages': true,
    'Marketing emails': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 32),
        children: [
          SectionHeader('Notifications'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 4),
            child: Column(
              children: [
                for (final entry in _toggles.entries)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.green,
                    title: Text(entry.key, style: AppText.body),
                    value: entry.value,
                    onChanged: (v) => setState(() => _toggles[entry.key] = v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          SectionHeader('Security'),
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => toast(context, 'Password reset link sent to your email'),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: Gap.md),
                Expanded(child: Text('Change password', style: AppText.body)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Center(
            child: Text('Aegis · version 0.1.0', style: AppText.caption),
          ),
        ],
      ),
    );
  }
}