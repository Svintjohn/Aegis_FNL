import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DepositScreen extends ConsumerStatefulWidget {
  final String projectId;
  const DepositScreen({super.key, required this.projectId});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  int _method = 0;
  bool _busy = false;

  static const _methods = [
    (Icons.account_balance_wallet_outlined, 'GCash', 'Instant · no fee'),
    (Icons.credit_card_rounded, 'Maya', 'Instant · no fee'),
    (Icons.currency_bitcoin_rounded, 'USDC (Coins.ph)', 'Around 5 minutes'),
  ];

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(storeProvider).project(widget.projectId);
    if (project == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Lock the budget')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                Text('You are locking', style: AppText.caption),
                const SizedBox(height: 4),
                Text(peso(project.budget), style: AppText.display.copyWith(fontSize: 34)),
                const SizedBox(height: 6),
                Text(project.title, style: AppText.body),
                const Divider(height: Gap.lg + 6),
                for (final m in project.milestones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(m.title, style: AppText.caption)),
                        Text('${m.percent}% · ${peso(m.amount)}',
                            style: AppText.caption.copyWith(
                                color: AppColors.ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          SectionHeader('Pay with'),
          for (var i = 0; i < _methods.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                border: _method == i ? AppColors.navy : null,
                onTap: () => setState(() => _method = i),
                child: Row(
                  children: [
                    Icon(_methods[i].$1, size: 22, color: AppColors.navy),
                    const SizedBox(width: Gap.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_methods[i].$2, style: AppText.title.copyWith(fontSize: 14)),
                          Text(_methods[i].$3, style: AppText.caption),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _method == i ? AppColors.navy : AppColors.line,
                          width: 2,
                        ),
                        color: _method == i ? AppColors.navy : Colors.transparent,
                      ),
                      child: _method == i
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.md),
          _Reassurance(
            text: 'Aegis holds this money. It only moves when you approve a '
                'milestone, or if the 14-day review window lapses.',
          ),
          const SizedBox(height: Gap.lg),
          AppButton(
            'Lock ${peso(project.budget)}',
            tone: ButtonTone.green,
            icon: Icons.lock_outline_rounded,
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              await Future.delayed(const Duration(milliseconds: 900));
              if (!mounted) return;
              ref.read(storeProvider.notifier).fundProject(project.id);
              setState(() => _busy = false);
              toast(context, 'Funds locked — the freelancer can start now', good: true);
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amount = TextEditingController();
  int _destination = 0;
  bool _busy = false;
  String? _error;

  static const _destinations = ['GCash · 0917 ••• 4823', 'Maya · 0995 ••• 1140'];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _withdraw(double balance) async {
    final value = double.tryParse(_amount.text.replaceAll(',', ''));
    setState(() {
      if (value == null || value <= 0) {
        _error = 'Enter an amount';
      } else if (value > balance) {
        _error = "That's more than your available balance";
      } else {
        _error = null;
      }
    });
    if (_error != null) return;

    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    ref.read(storeProvider.notifier).withdraw(value!);
    setState(() {
      _busy = false;
      _amount.clear();
    });
    toast(context, '${peso(value)} sent to ${_destinations[_destination]}', good: true);
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(storeProvider).walletBalance;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.greenDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available to withdraw',
                    style: AppText.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(peso(balance),
                    style: AppText.display.copyWith(color: Colors.white, fontSize: 32)),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          SectionHeader('Withdraw'),
          AppField(
            label: 'Amount',
            hint: '0.00',
            icon: Icons.payments_outlined,
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              for (final preset in [500.0, 1000.0, balance])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Pressable(
                    onTap: () => setState(() {
                      _amount.text = preset.toStringAsFixed(2);
                      _error = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.line.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        preset == balance ? 'All' : peso(preset),
                        style: AppText.caption.copyWith(
                            color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.md + 4),
          SectionHeader('Send to'),
          for (var i = 0; i < _destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                border: _destination == i ? AppColors.navy : null,
                onTap: () => setState(() => _destination = i),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 21, color: AppColors.navy),
                    const SizedBox(width: Gap.sm + 4),
                    Expanded(child: Text(_destinations[i], style: AppText.body)),
                    if (_destination == i)
                      const Icon(Icons.check_circle, size: 20, color: AppColors.navy),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.md),
          _Reassurance(
            text: 'Transfers to GCash and Maya usually land within a few minutes. '
                'Crypto off-ramping is simulated in this build.',
          ),
          const SizedBox(height: Gap.lg),
          AppButton(
            'Withdraw',
            tone: ButtonTone.green,
            busy: _busy,
            onPressed: balance <= 0 ? null : () => _withdraw(balance),
          ),
        ],
      ),
    );
  }
}

class _Reassurance extends StatelessWidget {
  final String text;
  const _Reassurance({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 17, color: AppColors.navy),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: AppText.caption)),
        ],
      ),
    );
  }
}
