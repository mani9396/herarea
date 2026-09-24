import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import '../../state/chat_providers.dart';
import '../../../../data/services/chat_websocket_service.dart';


class VendorChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const VendorChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends ConsumerState<VendorChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message exceeds maximum length of 2000 characters.')),
      );
      return;
    }

    ref.read(activeChatProvider(widget.conversationId).notifier).sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(activeChatProvider(widget.conversationId));
    final wsState = ref.watch(chatWebSocketServiceProvider.select((s) => s.connectionStateStream));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        elevation: 1,
        actions: [
          StreamBuilder<ChatConnectionState>(
            stream: wsState,
            builder: (context, snapshot) {
              final state = snapshot.data ?? ChatConnectionState.disconnected;
              IconData icon;
              Color color;
              switch (state) {
                case ChatConnectionState.connected:
                  icon = Icons.wifi_rounded;
                  color = Colors.green;
                  break;
                case ChatConnectionState.connecting:
                  icon = Icons.wifi_protected_setup_rounded;
                  color = Colors.orange;
                  break;
                case ChatConnectionState.error:
                  icon = Icons.wifi_off_rounded;
                  color = Colors.red;
                  break;
                case ChatConnectionState.disconnected:
                  icon = Icons.cloud_off_rounded;
                  color = Colors.grey;
                  break;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(icon, color: color, size: 20),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No Messages Yet',
                    description: 'Start the conversation by sending a message.',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Display latest at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUserId = ref.read(authSessionProvider).currentUser?.id;
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    final timeString = DateFormat('h:mm a').format(message.createdAt.toLocal());
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryRuby : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.neutralCharcoal,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 1,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    counterText: '', // Hide default counter to save space
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                color: AppColors.primaryRuby,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
