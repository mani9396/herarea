import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared/shared.dart';
class VendorChatScreen extends ConsumerStatefulWidget {
  
  final String conversationId;

  const VendorChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends ConsumerState<VendorChatScreen> {
  final _textController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  final _focusNode = FocusNode();
  ChatMessageModel? _replyingTo;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
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

    ref.read(activeChatProvider(widget.conversationId).notifier).sendMessage(text, replyToId: _replyingTo?.id);
    _textController.clear();
    setState(() {
      _replyingTo = null;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(activeChatProvider(widget.conversationId));
    final wsState = ref.watch(chatWebSocketServiceProvider.select((s) => s.connectionStateStream));

    final conversations = ref.watch(chatConversationsProvider).value ?? [];
    ChatConversationModel? conversation;
    try {
      conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
    } catch (_) {}

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
          ),
          if (conversation != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block' || value == 'unblock') {
                  try {
                    await ref.read(chatApiRepositoryProvider).blockConversation(widget.conversationId, value);
                    ref.invalidate(chatConversationsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              itemBuilder: (context) {
                final isBlocked = conversation!.blockedByVendor;
                return [
                  PopupMenuItem(
                    value: isBlocked ? 'unblock' : 'block',
                    child: Text(isBlocked ? 'Unblock Customer' : 'Block Customer'),
                  ),
                ];
              },
            ),
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

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  reverse: true, // Display latest at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUserId = conversation?.vendor.id ?? ref.read(authSessionProvider).currentUser?.id;
                    final isMe = message.senderId == currentUserId;

                    bool showDateHeader = false;
                    if (index == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final current = message.createdAt.toLocal();
                      final previous = messages[index + 1].createdAt.toLocal();
                      if (current.day != previous.day || current.month != previous.month || current.year != previous.year) {
                        showDateHeader = true;
                      }
                    }

                    Widget bubble = _buildMessageBubble(
                      message: message,
                      isMe: isMe,
                      conversation: conversation,
                      onReplyTapped: () {
                        if (message.replyTo != null) {
                          final replyIndex = messages.indexWhere((m) => m.id == message.replyTo!.id);
                          if (replyIndex != -1) {
                            _itemScrollController.scrollTo(
                              index: replyIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        }
                      },
                    );

                    if (showDateHeader) {
                      return Column(
                        children: [
                          _buildDateHeader(message.createdAt.toLocal()),
                          bubble,
                        ],
                      );
                    }
                    return bubble;
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          
          _buildMessageInput(conversation),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessageModel message,
    required bool isMe,
    required ChatConversationModel? conversation,
    VoidCallback? onReplyTapped,
  }) {
    final timeString = DateFormat('h:mm a').format(message.createdAt.toLocal());
    
    final currentUserId = conversation?.vendor.id ?? ref.read(authSessionProvider).currentUser?.id;
    
    return SwipeTo(
      onRightSwipe: (details) {
        setState(() {
          _replyingTo = message;
        });
        _focusNode.requestFocus();
      },
      child: Align(
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
              if (message.replyTo != null)
                GestureDetector(
                  onTap: onReplyTapped,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyTo!.senderId == currentUserId ? 'You' : 'Customer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isMe ? Colors.white70 : AppColors.primaryRuby,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.replyTo!.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
    );
  }

  Widget _buildBlockedBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.grey.shade200,
      child: SafeArea(
        top: false,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatConversationModel? conversation) {
    if (conversation != null) {
      if (conversation.blockedByVendor) {
        return _buildBlockedBanner('You blocked this customer.');
      } else if (conversation.blockedByCustomer) {
        return _buildBlockedBanner('You have been blocked by this customer.');
      }
    }

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
        child: Column(
          children: [
            if (_replyingTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to...',
                            style: TextStyle(
                              color: AppColors.primaryRuby,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _replyingTo!.message,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _replyingTo = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Row(
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
                      focusNode: _focusNode,
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
          ],
        ),
      ),
    );
  }
}
