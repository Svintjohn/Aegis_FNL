import 'package:flutter/material.dart';
import '../theme.dart';

/// Buttons and cards shrink slightly while held. Cheap, but it's most of
/// what makes the app feel responsive rather than flat.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

enum ButtonTone { navy, green, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.tone = ButtonTone.navy,
    this.icon,
    this.busy = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    final outlined = tone == ButtonTone.outline;

    final colors = switch (tone) {
      ButtonTone.navy => AppColors.navyGradient,
      ButtonTone.green => AppColors.greenGradient,
      ButtonTone.danger => const [AppColors.red, Color(0xFFDC2626)],
      ButtonTone.outline => const [Colors.transparent, Colors.transparent],
    };
    final fg = outlined ? AppColors.navy : Colors.white;

    return Opacity(
      opacity: disabled && !busy ? 0.45 : 1,
      child: Pressable(
        onTap: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          width: fullWidth ? double.infinity : null,
          padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: outlined ? Border.all(color: AppColors.navy, width: 1.5) : null,
            boxShadow: outlined || disabled
                ? null
                : [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: AppText.title.copyWith(color: fg, fontSize: 15)),
                  ],
                ),
        ),
      ),
    );
  }
}

class AppField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final int maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.maxLines = 1,
    this.controller,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final _focus = FocusNode();
  late bool _hidden = widget.obscure;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.red
        : _focused
            ? AppColors.navy
            : AppColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppText.caption.copyWith(
                color: AppColors.ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: _focused || hasError ? 1.6 : 1),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.red : AppColors.navy)
                          .withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: _hidden,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: AppText.body,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: AppText.body.copyWith(color: AppColors.muted),
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon,
                      size: 19,
                      color: _focused ? AppColors.navy : AppColors.muted),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 19,
                        color: AppColors.muted,
                      ),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.icon == null ? 14 : 0, vertical: 14),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(widget.errorText!,
                style: AppText.caption.copyWith(color: AppColors.red)),
          ),
      ],
    );
  }
}

/// White rounded surface used for every list item and panel.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.md),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: border == null ? null : Border.all(color: border!, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, scale: 0.985, child: card);
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill(this.label, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppText.caption
                  .copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final String label;
  const SkillChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label, style: AppText.caption.copyWith(fontSize: 11.5)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.heading.copyWith(fontSize: 17)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.caption.copyWith(
                      color: AppColors.navy, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: Gap.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.line, shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: AppColors.muted),
          ),
          const SizedBox(height: Gap.md),
          Text(title, style: AppText.title),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: AppText.caption),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool verified;

  const Avatar(this.name, {super.key, this.radius = 22, this.verified = false});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy.withValues(alpha: 0.1),
      child: Text(initials,
          style: AppText.title.copyWith(
              color: AppColors.navy, fontSize: radius * 0.62)),
    );

    if (!verified) return avatar;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
              child: Icon(Icons.verified,
                  color: AppColors.green, size: radius * 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

void toast(BuildContext context, String message, {bool good = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(good ? Icons.check_circle_outline : Icons.info_outline,
              size: 18, color: good ? AppColors.green : Colors.white70),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 3),
    ));
}
