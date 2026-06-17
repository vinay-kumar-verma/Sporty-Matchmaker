import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/chat_repository.dart';
import '../../domain/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>(
        (ref, gameId) {
  return ref.watch(chatRepositoryProvider).getMessages(gameId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String gameName;

  const ChatScreen(
      {super.key, required this.gameId, required this.gameName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final userModel =
        await ref.read(authRepositoryProvider).getUser(user.uid);
    await ref.read(chatRepositoryProvider).sendMessage(
          gameId: widget.gameId,
          senderId: user.uid,
          senderName: userModel?.name ?? 'Anonymous',
          text: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesProvider(widget.gameId));
    final currentUser =
        ref.watch(authRepositoryProvider).currentUser;

    // Get host ID from game stream
    final hostId = ref
        .watch(chatRepositoryProvider)
        .getHostId(widget.gameId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.gameName),
            const Text(
              'Group Chat',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(
                        color: AppColors.error)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text('💬',
                            style:
                                TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              color:
                                  AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Be the first to say something!',
                          style: TextStyle(
                              color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return FutureBuilder<String?>(
                  future: hostId,
                  builder: (context, hostSnapshot) {
                    final hostUid = hostSnapshot.data;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId ==
                            currentUser?.uid;
                        final isHost =
                            message.senderId == hostUid;
                        return _MessageBubble(
                          message: message,
                          isMe: isMe,
                          isHost: isHost,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isHost;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceLight,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (isHost) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Host',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:
                          const Radius.circular(16),
                      topRight:
                          const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isMe ? 16 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: AppColors.cardBorder),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.black
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput(
      {required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(
                    color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}