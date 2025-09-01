import 'package:hive/hive.dart';
import 'package:language_chat/domain/entities/chat_conversation.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  static const String _conversationsBoxName = 'conversations';
  static const String _messagesBoxName = 'messages';

  late Box<Map> _conversationsBox;
  late Box<Map> _messagesBox;

  Future<void> init() async {
    _conversationsBox = await Hive.openBox<Map>(_conversationsBoxName);
    _messagesBox = await Hive.openBox<Map>(_messagesBoxName);
  }

  @override
  Future<List<ChatConversation>> getAllConversations() async {
    final conversationMaps = _conversationsBox.values.toList();
    final conversations = <ChatConversation>[];

    for (final map in conversationMaps) {
      final conversation = ChatConversation.fromJson(
        Map<String, dynamic>.from(map),
      );
      final messages = await getMessagesForConversation(conversation.id);
      conversations.add(conversation.copyWith(messages: messages));
    }

    return conversations
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  @override
  Future<ChatConversation?> getConversationById(String id) async {
    final conversationMap = _conversationsBox.get(id);
    if (conversationMap == null) return null;

    final conversation = ChatConversation.fromJson(
      Map<String, dynamic>.from(conversationMap),
    );
    final messages = await getMessagesForConversation(id);
    return conversation.copyWith(messages: messages);
  }

  @override
  Future<ChatConversation?> getConversationByContactId(String contactId) async {
    final conversations = await getAllConversations();
    try {
      return conversations.firstWhere((conv) => conv.contactId == contactId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ChatConversation> createConversation(
    ChatConversation conversation,
  ) async {
    await _conversationsBox.put(conversation.id, conversation.toJson());
    return conversation;
  }

  @override
  Future<ChatConversation> updateConversation(
    ChatConversation conversation,
  ) async {
    await _conversationsBox.put(conversation.id, conversation.toJson());
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _conversationsBox.delete(id);
    // Also delete all messages for this conversation
    final messages = await getMessagesForConversation(id);
    for (final message in messages) {
      await _messagesBox.delete(message.id);
    }
  }

  @override
  Future<List<ChatMessage>> getMessagesForConversation(
    String conversationId,
  ) async {
    final messageMaps = _messagesBox.values
        .where((map) => map['chatId'] == conversationId)
        .toList();

    final messages = messageMaps
        .map((map) => ChatMessage.fromJson(Map<String, dynamic>.from(map)))
        .toList();

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  @override
  Future<ChatMessage> addMessage(ChatMessage message) async {
    await _messagesBox.put(message.id, message.toJson());

    // Update conversation's lastMessageAt
    final conversation = await getConversationById(message.chatId);
    if (conversation != null) {
      final updatedConversation = conversation.copyWith(
        lastMessageAt: message.timestamp,
        unreadCount: message.isFromUser
            ? conversation.unreadCount
            : conversation.unreadCount + 1,
      );
      await updateConversation(updatedConversation);
    }

    return message;
  }

  @override
  Future<ChatMessage> updateMessage(ChatMessage message) async {
    await _messagesBox.put(message.id, message.toJson());
    return message;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _messagesBox.delete(messageId);
  }

  @override
  Stream<List<ChatConversation>> watchConversations() {
    return _conversationsBox
        .watch()
        .map((_) => getAllConversations())
        .asyncMap((future) => future);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _messagesBox
        .watch()
        .map((_) => getMessagesForConversation(conversationId))
        .asyncMap((future) => future);
  }
}
