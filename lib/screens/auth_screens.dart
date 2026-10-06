import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../data/supabase_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Brand extends StatelessWidget {
  final double size;
  const _Brand({this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.navyGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.shield_outlined, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Fades and lifts its children in one after another on first build.
class _Entrance extends StatelessWidget {
  final List<Widget> children;
  const _Entrance({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 380 + i * 70),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
            ),
            child: children[i],
          ),
      ],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = _email.text.contains('@') ? null : 'Enter a valid email address';
      _passwordError = _password.text.length >= 6 ? null : 'At least 6 characters';
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/role');
    } on AuthException catch (e) {
      if (!mounted) return;
      toast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      toast(context, 'Could not log in: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, 40, Gap.lg, Gap.lg),
          child: _Entrance(
            children: [
              const _Brand(),
              const SizedBox(height: Gap.lg),
              Text('Welcome back', style: AppText.display),
              const SizedBox(height: 6),
              Text('Log in to keep your projects moving securely.',
                  style: AppText.body.copyWith(color: AppColors.muted)),
              const SizedBox(height: 32),
              AppField(
                label: 'Email',
                hint: 'Enter your Email',
                icon: Icons.mail_outline,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: Gap.md),
              AppField(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                obscure: true,
                controller: _password,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: Text('Forgot password?',
                      style: AppText.caption.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              AppButton('Log In',
                  onPressed: _submit, busy: _busy, icon: Icons.arrow_forward_rounded),
              const SizedBox(height: Gap.lg),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New to Aegis? ",
                        style: AppText.body.copyWith(color: AppColors.muted)),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text('Create an account',
                          style: AppText.title
                              .copyWith(color: AppColors.navy, fontSize: 14.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _errors = <String, String?>{};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errors['name'] = _name.text.trim().isEmpty ? 'Tell us your name' : null;
      _errors['email'] = _email.text.contains('@') ? null : 'Enter a valid email address';
      _errors['password'] =
          _password.text.length >= 6 ? null : 'At least 6 characters';
    });
    if (_errors.values.any((e) => e != null)) return;

    setState(() => _busy = true);
    try {
      // full_name is passed as user metadata; a database trigger
      // (handle_new_user in supabase_schema.sql) reads it and creates the
      // matching row in profiles automatically. We don't insert into
      // profiles directly here, since RLS would reject it before email
      // confirmation finishes.
      await supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'full_name': _name.text.trim()},
      );
      if (!mounted) return;
      context.go('/role');
    } on AuthException catch (e) {
      if (!mounted) return;
      toast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      toast(context, 'Could not sign up: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          child: _Entrance(
            children: [
              Text('Create your account', style: AppText.display),
              const SizedBox(height: 6),
              Text('Join Aegis and work with confidence.',
                  style: AppText.body.copyWith(color: AppColors.muted)),
              const SizedBox(height: 28),
              AppField(
                label: 'Full name',
                hint: 'Juan Dela Cruz',
                icon: Icons.person_outline,
                controller: _name,
                errorText: _errors['name'],
              ),
              const SizedBox(height: Gap.md),
              AppField(
                label: 'Email',
                hint: 'Enter your Email',
                icon: Icons.mail_outline,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                errorText: _errors['email'],
              ),
              const SizedBox(height: Gap.md),
              AppField(
                label: 'Password',
                hint: 'At least 6 characters',
                icon: Icons.lock_outline,
                obscure: true,
                controller: _password,
                errorText: _errors['password'],
              ),
              const SizedBox(height: Gap.lg),
              AppButton('Create Account',
                  onPressed: _submit, busy: _busy, icon: Icons.arrow_forward_rounded),
              const SizedBox(height: Gap.md),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('I already have an account',
                      style: AppText.caption.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: _sent
            ? Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.mark_email_read_outlined,
                      size: 52, color: AppColors.green),
                  const SizedBox(height: Gap.md),
                  Text('Check your inbox', style: AppText.heading),
                  const SizedBox(height: 6),
                  Text(
                    'If an account exists for ${_email.text}, a reset link is on its way.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: Gap.lg),
                  AppButton('Back to login',
                      tone: ButtonTone.outline, onPressed: () => context.go('/login')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("We'll email you a reset link.",
                      style: AppText.body.copyWith(color: AppColors.muted)),
                  const SizedBox(height: Gap.lg),
                  AppField(
                    label: 'Email',
                    hint: 'you@email.com',
                    icon: Icons.mail_outline,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: Gap.lg),
                  AppButton('Send reset link', onPressed: _send, busy: _busy),
                ],
              ),
      ),
    );
  }
}

class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: _Entrance(
            children: [
              const SizedBox(height: Gap.md),
              Text('How will you use Aegis today?',
                  style: AppText.display.copyWith(fontSize: 25)),
              const SizedBox(height: 8),
              Text('You can switch anytime from the top of your dashboard.',
                  style: AppText.body.copyWith(color: AppColors.muted)),
              const SizedBox(height: 28),
              _RoleCard(
                title: "I'm a Client",
                subtitle: 'Post projects and hire trusted student talent.',
                icon: Icons.business_center_outlined,
                colors: AppColors.navyGradient,
                onTap: () {
                  ref.read(roleProvider.notifier).state = Role.client;
                  context.go('/home');
                },
              ),
              const SizedBox(height: Gap.md),
              _RoleCard(
                title: "I'm a Freelancer",
                subtitle: 'Find gigs and get paid with locked-fund protection.',
                icon: Icons.laptop_mac_outlined,
                colors: AppColors.greenGradient,
                onTap: () {
                  ref.read(roleProvider.notifier).state = Role.freelancer;
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.title.copyWith(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: AppText.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }
}