class ChatParticipantModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;

  ChatParticipantModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Unknown User',
      phoneNumber: json['phone_number']?.toString(),
      role: json['role']?.toString() ?? '',
    );
  }
}

class ChatConversationModel {
  final String id;
  final ChatParticipantModel customer;
  final ChatParticipantModel vendor;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  ChatConversationModel({
    required this.id,
    required this.customer,
    required this.vendor,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id']?.toString() ?? '',
      customer: ChatParticipantModel.fromJson(json['customer'] ?? {}),
      vendor: ChatParticipantModel.fromJson(json['vendor'] ?? {}),
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) ?? DateTime.now() : DateTime.now(),
      unreadCount: json['unread_count'] is int ? json['unread_count'] as int : 0,
    );
  }

  ChatConversationModel copyWith({
    String? id,
    ChatParticipantModel? customer,
    ChatParticipantModel? vendor,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      vendor: vendor ?? this.vendor,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation']?.toString() ?? '',
      senderId: json['sender']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? message,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
