enum MessageType { text, audio, system, moderatorTip }

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? audioPath;
  final Duration? audioDuration;
  final String? replyToMessageId;
  final bool isFromUser;
  final bool isModerator;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.audioPath,
    this.audioDuration,
    this.replyToMessageId,
    required this.isFromUser,
    this.isModerator = false,
  });

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? audioPath,
    Duration? audioDuration,
    String? replyToMessageId,
    bool? isFromUser,
    bool? isModerator,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isFromUser: isFromUser ?? this.isFromUser,
      isModerator: isModerator ?? this.isModerator,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'audioDuration': audioDuration?.inMilliseconds,
      'replyToMessageId': replyToMessageId,
      'isFromUser': isFromUser,
      'isModerator': isModerator,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],
      audioDuration: json['audioDuration'] != null
          ? Duration(milliseconds: json['audioDuration'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      isFromUser: json['isFromUser'],
      isModerator: json['isModerator'] ?? false,
    );
  }
}
