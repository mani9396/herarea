import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import '../../state/chat_providers.dart';

class VendorChatListScreen extends ConsumerWidget {
  const VendorChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No Messages Yet',
              description: 'When customers initiate a chat with you, they will appear here.',
            );
          }

          // Sort so latest messages are at the top
          final sortedConversations = List<ChatConversationModel>.from(conversations)
            ..sort((a, b) {
              final aDate = a.lastMessageAt ?? a.createdAt;
              final bDate = b.lastMessageAt ?? b.createdAt;
              return bDate.compareTo(aDate);
            });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatConversationsProvider);
              await ref.read(chatConversationsProvider.future);
            },
            color: AppColors.primaryRuby,
            child: ListView.separated(
              itemCount: sortedConversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final conversation = sortedConversations[index];
                final customerName = conversation.customer.fullName;
                
                String timeString = '';
                if (conversation.lastMessageAt != null) {
                  final now = DateTime.now();
                  final diff = now.difference(conversation.lastMessageAt!);
                  if (diff.inDays == 0 && now.day == conversation.lastMessageAt!.day) {
                    timeString = DateFormat('h:mm a').format(conversation.lastMessageAt!);
                  } else if (diff.inDays < 7) {
                    timeString = DateFormat('EEEE').format(conversation.lastMessageAt!);
                  } else {
                    timeString = DateFormat('MMM d, yyyy').format(conversation.lastMessageAt!);
                  }
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryRuby,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: TextStyle(
                            color: conversation.unreadCount > 0 ? AppColors.primaryRuby : Colors.grey,
                            fontSize: 12,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessageAt != null ? 'Open to view messages' : 'New conversation',
                            style: TextStyle(
                              color: conversation.unreadCount > 0 ? AppColors.neutralCharcoal : Colors.grey.shade600,
                              fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRuby,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // Navigate to chat detail screen
                    context.push('/chat/${conversation.id}');
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
        error: (e, st) => EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Error Loading Messages',
          description: 'Failed to load conversations: $e',
        ),
      ),
    );
  }
}
