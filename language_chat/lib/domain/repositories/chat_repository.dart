import 'package:langchat/domain/entities/chat_conversation.dart';
import 'package:langchat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatConversation>> getAllConversations();
  Future<ChatConversation?> getConversationById(String id);
  Future<ChatConversation?> getConversationByContactId(String contactId);
  Future<ChatConversation> createConversation(ChatConversation conversation);
  Future<ChatConversation> updateConversation(ChatConversation conversation);
  Future<void> deleteConversation(String id);

  Future<List<ChatMessage>> getMessagesForConversation(String conversationId);
  Future<ChatMessage> addMessage(ChatMessage message);
  Future<ChatMessage> updateMessage(ChatMessage message);
  Future<void> deleteMessage(String messageId);
  Future<void> clearMessagesForConversation(String conversationId);

  Stream<List<ChatConversation>> watchConversations();
  Stream<List<ChatMessage>> watchMessages(String conversationId);
}
