import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../data/repositories/chat_api_repository.dart';
import '../../../data/services/chat_websocket_service.dart';

final chatConversationsProvider = FutureProvider.autoDispose<List<ChatConversationModel>>((ref) async {
  final chatRepo = ref.watch(chatApiRepositoryProvider);
  return chatRepo.getConversations();
});

class ActiveChatNotifier extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final ChatApiRepository _chatApiRepository;
  final ChatWebSocketService _chatWebSocketService;
  final String _conversationId;

  ActiveChatNotifier(this._chatApiRepository, this._chatWebSocketService, this._conversationId) 
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Fetch initial message history
      final messages = await _chatApiRepository.getMessages(_conversationId);
      state = AsyncValue.data(messages);

      // 2. Mark as read
      await _chatApiRepository.markAsRead(_conversationId);

      // 3. Setup WebSocket connection
      await _chatWebSocketService.connect(_conversationId);

      // 4. Subscribe to new messages
      _chatWebSocketService.messageStream.listen((newMessage) {
        state.whenData((currentMessages) {
          // Avoid duplicates by checking ID
          if (!currentMessages.any((m) => m.id == newMessage.id)) {
            state = AsyncValue.data([newMessage, ...currentMessages]);
            // Attempt to mark as read since we are actively looking at it
            _chatApiRepository.markAsRead(_conversationId);
          }
        });
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String text) async {
    _chatWebSocketService.sendMessage(text);
  }

  @override
  void dispose() {
    _chatWebSocketService.disconnect();
    super.dispose();
  }
}

final activeChatProvider = StateNotifierProvider.family.autoDispose<ActiveChatNotifier, AsyncValue<List<ChatMessageModel>>, String>((ref, conversationId) {
  final chatRepo = ref.watch(chatApiRepositoryProvider);
  final wsService = ref.watch(chatWebSocketServiceProvider);
  return ActiveChatNotifier(chatRepo, wsService, conversationId);
});
