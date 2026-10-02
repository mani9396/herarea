import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';

class CustomerChatListScreen extends ConsumerWidget {
  const CustomerChatListScreen({super.key});

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No Messages Yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('When you contact a store, your conversations will appear here.', style: TextStyle(color: Colors.grey)),
                ],
              ),
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
                final vendorName = conversation.vendor.fullName;
                
                String timeAgo = '';
                if (conversation.lastMessageAt != null) {
                  final now = DateTime.now();
                  final diff = now.difference(conversation.lastMessageAt!);
                  if (diff.inDays > 0) {
                    timeAgo = DateFormat.MMMd().format(conversation.lastMessageAt!);
                  } else {
                    timeAgo = DateFormat.jm().format(conversation.lastMessageAt!);
                  }
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.blushPink.withValues(alpha: 0.5),
                    child: Text(vendorName.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vendorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Message history',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: conversation.unreadCount > 0 ? Colors.black87 : Colors.grey,
                              fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRuby,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    context.push('/chat/${conversation.id}');
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
        error: (e, st) => Center(child: Text('Failed to load conversations: $e')),
      ),
    );
  }
}