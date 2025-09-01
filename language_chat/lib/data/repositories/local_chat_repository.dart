import 'package:hive/hive.dart';
import 'package:language_chat/domain/entities/chat_conversation.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  static const String _conversationsBoxName = 'conversations';
  static const String _messagesBoxName = 'messages';

  late Box _conversationsBox;
  late Box _messagesBox;

  Future<void> init() async {
    _conversationsBox = await Hive.openBox(_conversationsBoxName);
    _messagesBox = await Hive.openBox(_messagesBoxName);
    print('📦 ChatRepository inicializado'); // Debug
  }

  @override
  Future<List<ChatConversation>> getAllConversations() async {
    try {
      final conversationMaps = _conversationsBox.values.toList();
      print(
        '💬 Carregando ${conversationMaps.length} conversas do Hive',
      ); // Debug

      final conversations = <ChatConversation>[];

      for (final conversationData in conversationMaps) {
        try {
          // Convert to proper Map<String, dynamic>
          final Map<String, dynamic> conversationMap =
              Map<String, dynamic>.from(conversationData as Map);
          final conversation = ChatConversation.fromJson(conversationMap);

          // Load messages for this conversation
          final messages = await getMessagesForConversation(conversation.id);
          final conversationWithMessages = conversation.copyWith(
            messages: messages,
          );

          conversations.add(conversationWithMessages);
        } catch (e) {
          print('⚠️ Erro ao converter conversa: $e'); // Debug
          // Skip invalid conversation
          continue;
        }
      }

      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      print(
        '✅ ${conversations.length} conversas carregadas com sucesso',
      ); // Debug
      return conversations;
    } catch (e) {
      print('❌ Erro ao carregar conversas: $e'); // Debug
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<ChatConversation?> getConversationById(String id) async {
    try {
      final conversationData = _conversationsBox.get(id);
      if (conversationData == null) return null;

      final Map<String, dynamic> conversationMap = Map<String, dynamic>.from(
        conversationData as Map,
      );
      final conversation = ChatConversation.fromJson(conversationMap);
      final messages = await getMessagesForConversation(id);
      return conversation.copyWith(messages: messages);
    } catch (e) {
      print('❌ Erro ao buscar conversa $id: $e'); // Debug
      return null;
    }
  }

  @override
  Future<ChatConversation?> getConversationByContactId(String contactId) async {
    try {
      final conversations = await getAllConversations();
      return conversations.firstWhere(
        (conv) => conv.contactId == contactId,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null; // Return null if not found
    }
  }

  @override
  Future<ChatConversation> createConversation(
    ChatConversation conversation,
  ) async {
    try {
      await _conversationsBox.put(conversation.id, conversation.toJson());
      print('✅ Conversa ${conversation.id} criada'); // Debug
      return conversation;
    } catch (e) {
      print('❌ Erro ao criar conversa: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<ChatConversation> updateConversation(
    ChatConversation conversation,
  ) async {
    try {
      await _conversationsBox.put(conversation.id, conversation.toJson());
      print('✅ Conversa ${conversation.id} atualizada'); // Debug
      return conversation;
    } catch (e) {
      print('❌ Erro ao atualizar conversa: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _conversationsBox.delete(id);
      // Also delete all messages for this conversation
      final messages = await getMessagesForConversation(id);
      for (final message in messages) {
        await _messagesBox.delete(message.id);
      }
      print('✅ Conversa $id deletada'); // Debug
    } catch (e) {
      print('❌ Erro ao deletar conversa: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<List<ChatMessage>> getMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final messageMaps = _messagesBox.values.toList();
      final conversationMessages = <ChatMessage>[];

      for (final messageData in messageMaps) {
        try {
          final Map<String, dynamic> messageMap = Map<String, dynamic>.from(
            messageData as Map,
          );

          if (messageMap['chatId'] == conversationId) {
            final message = ChatMessage.fromJson(messageMap);
            conversationMessages.add(message);
          }
        } catch (e) {
          print('⚠️ Erro ao converter mensagem: $e'); // Debug
          // Skip invalid message
          continue;
        }
      }

      conversationMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return conversationMessages;
    } catch (e) {
      print(
        '❌ Erro ao carregar mensagens para conversa $conversationId: $e',
      ); // Debug
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<ChatMessage> addMessage(ChatMessage message) async {
    try {
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

      print('✅ Mensagem ${message.id} adicionada'); // Debug
      return message;
    } catch (e) {
      print('❌ Erro ao adicionar mensagem: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<ChatMessage> updateMessage(ChatMessage message) async {
    try {
      await _messagesBox.put(message.id, message.toJson());
      return message;
    } catch (e) {
      print('❌ Erro ao atualizar mensagem: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messagesBox.delete(messageId);
    } catch (e) {
      print('❌ Erro ao deletar mensagem: $e'); // Debug
      rethrow;
    }
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
