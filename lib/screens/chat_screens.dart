import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(storeProvider);
    final withPartner = data.projects.where((p) => p.freelancerName != null).toList();

    if (withPartner.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No conversations yet',
        message: 'Chats open once a project has both a client and a freelancer.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 110),
      itemCount: withPartner.length,
      separatorBuilder: (_, __) => const SizedBox(height: Gap.sm + 2),
      itemBuilder: (context, i) {
        final project = withPartner[i];
        final thread = data.messages.where((m) => m.projectId == project.id).toList();
        final last = thread.isEmpty ? null : thread.last;
        final partner = ref.watch(roleProvider) == Role.client
            ? project.freelancerName!
            : project.clientName;

        return AppCard(
          padding: const EdgeInsets.all(13),
          onTap: () => context.push('/chat/${project.id}'),
          child: Row(
            children: [
              Avatar(partner, radius: 23),
              const SizedBox(width: Gap.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner, style: AppText.title.copyWith(fontSize: 14.5)),
                    Text(project.title,
                        style: AppText.caption.copyWith(fontSize: 11.5)),
                    const SizedBox(height: 3),
                    Text(
                      last?.text ?? 'Say hello to get started',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              if (last != null)
                Text(timeAgo(last.sentAt),
                    style: AppText.caption.copyWith(fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ChatScreen({super.key, required this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    ref.read(storeProvider.notifier).sendMessage(widget.projectId, text);
    _input.clear();

    // Let the new bubble lay out before scrolling to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(storeProvider);
    final project = data.project(widget.projectId);
    final thread = data.messages.where((m) => m.projectId == widget.projectId).toList();

    if (project == null) return const Scaffold(body: SizedBox.shrink());

    final partner = ref.watch(roleProvider) == Role.client
        ? (project.freelancerName ?? project.clientName)
        : project.clientName;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(partner, radius: 16),
            const SizedBox(width: Gap.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner, style: AppText.title.copyWith(fontSize: 14.5)),
                  Text(project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Open project',
            onPressed: () => context.push('/project/${project.id}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: thread.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'No messages yet',
                    message: 'Questions about scope belong here, not in DMs.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.sm),
                    itemCount: thread.length,
                    itemBuilder: (context, i) => _Bubble(message: thread[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.sm),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: AppText.body,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Write a message',
                        hintStyle: AppText.body.copyWith(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Pressable(
                    onTap: _send,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.navyGradient),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                    ),
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

class _Bubble extends StatelessWidget {
  final Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.navy : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(message.text,
                      style: AppText.body
                          .copyWith(color: mine ? Colors.white : AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(
                    timeAgo(message.sentAt),
                    style: AppText.caption.copyWith(
                      fontSize: 10.5,
                      color: mine ? Colors.white70 : AppColors.muted,
                    ),
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
