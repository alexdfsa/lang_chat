import 'package:langchat/domain/entities/chat_conversation.dart';
import 'package:langchat/domain/entities/chat_message.dart';
import 'package:langchat/domain/repositories/ai_service_repository.dart';
import 'package:langchat/domain/repositories/chat_repository.dart';
import 'package:langchat/domain/usecases/base_usecase.dart';

class StartConversationUseCase
    extends BaseUseCase<ChatConversation, StartConversationParams> {
  final ChatRepository chatRepository;

  StartConversationUseCase(this.chatRepository);

  @override
  Future<ChatConversation> call(StartConversationParams params) async {
    // Check if conversation already exists
    final existingConversation = await chatRepository
        .getConversationByContactId(params.contactId);

    if (existingConversation != null) {
      return existingConversation;
    }

    // Create new conversation
    final conversation = ChatConversation(
      id: params.conversationId,
      contactId: params.contactId,
      contactName: params.contactName,
      contactProfileImage: params.contactProfileImage,
      language: params.language,
      messages: [],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    return await chatRepository.createConversation(conversation);
  }
}

class StartConversationParams {
  final String conversationId;
  final String contactId;
  final String contactName;
  final String contactProfileImage;
  final String language;

  StartConversationParams({
    required this.conversationId,
    required this.contactId,
    required this.contactName,
    required this.contactProfileImage,
    required this.language,
  });
}

class SendMessageUseCase extends BaseUseCase<ChatMessage, SendMessageParams> {
  final ChatRepository chatRepository;
  final AIServiceRepository aiService;

  SendMessageUseCase(this.chatRepository, this.aiService);

  @override
  Future<ChatMessage> call(SendMessageParams params) async {
    // Check message safety first
    final isSafe = await aiService.checkMessageSafety(
      message: params.message.content,
      language: params.language,
    );

    if (!isSafe) {
      // Generate moderator warning
      final moderatorMessage = ChatMessage(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        chatId: params.message.chatId,
        senderId: 'moderator',
        senderName: 'Moderador',
        content:
            'Por favor, mantenha a conversa respeitosa e focada no aprendizado do idioma.',
        type: MessageType.moderatorTip,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
        isModerator: true,
      );

      await chatRepository.addMessage(moderatorMessage);
      throw Exception('Mensagem bloqueada pelo moderador');
    }

    // Add user message
    final userMessage = await chatRepository.addMessage(params.message);

    // Get conversation history for AI response
    final messages = await chatRepository.getMessagesForConversation(
      params.message.chatId,
    );

    // Generate AI response
    final aiResponse = await aiService.generateContactResponse(
      contactId: params.contactId,
      conversationId: params.message.chatId,
      conversationHistory: messages,
      userMessage: params.message.content,
      language: params.language,
    );

    await chatRepository.addMessage(aiResponse);

    // Check if moderator tip is needed
    final recentMessages = messages.length > 5
        ? messages.sublist(messages.length - 5)
        : messages;

    final moderatorTip = await aiService.generateModeratorTip(
      conversationId: params.message.chatId,
      recentMessages: recentMessages,
      targetLanguage: params.language,
    );

    if (moderatorTip != null) {
      await chatRepository.addMessage(moderatorTip);
    }

    return userMessage;
  }
}

class SendMessageParams {
  final ChatMessage message;
  final String contactId;
  final String language;

  SendMessageParams({
    required this.message,
    required this.contactId,
    required this.language,
  });
}

class SendAudioMessageUseCase
    extends BaseUseCase<ChatMessage, SendAudioMessageParams> {
  final ChatRepository chatRepository;
  final AIServiceRepository aiService;
  final SendMessageUseCase sendMessageUseCase;

  SendAudioMessageUseCase(
    this.chatRepository,
    this.aiService,
    this.sendMessageUseCase,
  );

  @override
  Future<ChatMessage> call(SendAudioMessageParams params) async {
    // Transcribe audio first
    final transcription = await aiService.transcribeAudio(params.audioPath);

    // Create audio message with transcription
    final audioMessage = params.message.copyWith(content: transcription);

    return await sendMessageUseCase.call(
      SendMessageParams(
        message: audioMessage,
        contactId: params.contactId,
        language: params.language,
      ),
    );
  }
}

class SendAudioMessageParams {
  final ChatMessage message;
  final String audioPath;
  final String contactId;
  final String language;

  SendAudioMessageParams({
    required this.message,
    required this.audioPath,
    required this.contactId,
    required this.language,
  });
}

class GetConversationsUseCase
    extends BaseUseCase<List<ChatConversation>, NoParams> {
  final ChatRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<List<ChatConversation>> call(NoParams params) {
    return repository.getAllConversations();
  }
}

class GetMessagesUseCase
    extends BaseUseCase<List<ChatMessage>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<List<ChatMessage>> call(GetMessagesParams params) {
    return repository.getMessagesForConversation(params.conversationId);
  }
}

class GetMessagesParams {
  final String conversationId;
  GetMessagesParams(this.conversationId);
}

class ClearConversationUseCase
    extends BaseUseCase<void, ClearConversationParams> {
  final ChatRepository repository;

  ClearConversationUseCase(this.repository);

  @override
  Future<void> call(ClearConversationParams params) async {
    await repository.clearMessagesForConversation(params.conversationId);
  }
}

class ClearConversationParams {
  final String conversationId;
  ClearConversationParams(this.conversationId);
}
