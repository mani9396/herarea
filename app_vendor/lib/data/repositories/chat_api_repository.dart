import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

final chatApiRepositoryProvider = Provider<ChatApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatApiRepository(apiClient);
});

class ChatApiRepository {
  final IApiClient _apiClient;

  ChatApiRepository(this._apiClient);

  Future<String?> getWsToken() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.chatWsToken);
      if (response['ws_token'] != null) {
        return response['ws_token'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ChatConversationModel>> getConversations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.chatConversations);
      
      List<dynamic> results = [];
      if (response.containsKey('results')) {
        results = response['results'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        results = response['data'] as List<dynamic>;
      }
      
      return results.map((c) => ChatConversationModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.chatMessages(conversationId));
      
      List<dynamic> results = [];
      if (response.containsKey('results')) {
        results = response['results'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        results = response['data'] as List<dynamic>;
      }
      
      return results.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> markAsRead(String conversationId) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.chatMarkRead(conversationId));
      return (response['success'] == true) || (response['status_code'] == 200);
    } catch (e) {
      return false;
    }
  }
}
