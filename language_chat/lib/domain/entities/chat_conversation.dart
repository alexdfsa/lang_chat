import 'package:langchat/domain/entities/chat_message.dart';

class ChatConversation {
  final String id;
  final String contactId;
  final String contactName;
  final String contactProfileImage;
  final String language;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isActive;

  const ChatConversation({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.contactProfileImage,
    required this.language,
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
  });

  ChatConversation copyWith({
    String? id,
    String? contactId,
    String? contactName,
    String? contactProfileImage,
    String? language,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isActive,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactProfileImage: contactProfileImage ?? this.contactProfileImage,
      language: language ?? this.language,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'contactName': contactName,
      'contactProfileImage': contactProfileImage,
      'language': language,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      contactId: json['contactId'],
      contactName: json['contactName'],
      contactProfileImage: json['contactProfileImage'],
      language: json['language'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
