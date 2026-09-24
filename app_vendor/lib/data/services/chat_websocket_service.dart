import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared/shared.dart';
import '../repositories/chat_api_repository.dart';

enum ChatConnectionState { disconnected, connecting, connected, error }

final chatWebSocketServiceProvider = Provider<ChatWebSocketService>((ref) {
  final chatApiRepo = ref.watch(chatApiRepositoryProvider);
  return ChatWebSocketService(chatApiRepo);
});

class ChatWebSocketService {
  final ChatApiRepository _chatApiRepository;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  final _connectionStateController = StreamController<ChatConnectionState>.broadcast();
  Stream<ChatConnectionState> get connectionStateStream => _connectionStateController.stream;

  ChatConnectionState _currentState = ChatConnectionState.disconnected;
  String? _currentConversationId;
  
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  ChatWebSocketService(this._chatApiRepository);

  Future<void> connect(String conversationId) async {
    _isDisposed = false;
    _currentConversationId = conversationId;
    _updateState(ChatConnectionState.connecting);

    try {
      final token = await _chatApiRepository.getWsToken();
      if (token == null) {
        _updateState(ChatConnectionState.error);
        _scheduleReconnect();
        return;
      }

      final baseUrl = ApiEndpoints.defaultBaseUrl;
      final wsBaseUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final wsUrl = '$wsBaseUrl/ws/chat/$conversationId/?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _reconnectAttempts = 0;
      _updateState(ChatConnectionState.connected);

      _channelSubscription = _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            if (decoded['type'] == 'message') {
              final msgJson = decoded['message'] as Map<String, dynamic>;
              final msg = ChatMessageModel.fromJson(msgJson);
              _messageController.add(msg);
            } else if (decoded['error'] != null) {
              debugPrint('WebSocket Error: ${decoded['error']}');
              // Could broadcast this error if needed for UI
            }
          } catch (e) {
            debugPrint('Failed to parse WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket stream error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket stream done');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_isDisposed) return;
    _updateState(ChatConnectionState.disconnected);
    _cleanupChannel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed || _currentConversationId == null) return;
    
    _reconnectTimer?.cancel();
    
    // Max delay of ~16 seconds (capped)
    final delaySeconds = (1 << _reconnectAttempts).clamp(1, 16);
    _reconnectAttempts++;
    
    _updateState(ChatConnectionState.connecting); // Reconnecting state
    
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && _currentConversationId != null) {
        connect(_currentConversationId!);
      }
    });
  }

  void sendMessage(String text) {
    if (_currentState == ChatConnectionState.connected && _channel != null) {
      _channel!.sink.add(jsonEncode({'message': text}));
    }
  }

  void _updateState(ChatConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void _cleanupChannel() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _isDisposed = true;
    _currentConversationId = null;
    _reconnectTimer?.cancel();
    _cleanupChannel();
    _updateState(ChatConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
