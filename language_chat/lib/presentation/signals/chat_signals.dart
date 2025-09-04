import 'package:language_chat/domain/entities/chat_conversation.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/domain/usecases/base_usecase.dart';
import 'package:language_chat/domain/usecases/chat_usecases.dart';
import 'package:signals/signals.dart';

class ChatSignals {
  final StartConversationUseCase _startConversationUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final SendAudioMessageUseCase _sendAudioMessageUseCase;
  final GetConversationsUseCase _getConversationsUseCase;
  final GetMessagesUseCase _getMessagesUseCase;

  ChatSignals({
    required StartConversationUseCase startConversationUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required SendAudioMessageUseCase sendAudioMessageUseCase,
    required GetConversationsUseCase getConversationsUseCase,
    required GetMessagesUseCase getMessagesUseCase,
  }) : _startConversationUseCase = startConversationUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _sendAudioMessageUseCase = sendAudioMessageUseCase,
       _getConversationsUseCase = getConversationsUseCase,
       _getMessagesUseCase = getMessagesUseCase;

  // Signals
  final _conversations = signal<List<ChatConversation>>([]);
  final _currentConversation = signal<ChatConversation?>(null);
  final _messages = signal<List<ChatMessage>>([]);
  final _isLoading = signal<bool>(false);
  final _isSendingMessage = signal<bool>(false);
  final _error = signal<String?>(null);
  final _typingMessage = signal<String>('');

  // Getters
  ReadonlySignal<List<ChatConversation>> get conversations =>
      _conversations.readonly();
  ReadonlySignal<ChatConversation?> get currentConversation =>
      _currentConversation.readonly();
  ReadonlySignal<List<ChatMessage>> get messages => _messages.readonly();
  ReadonlySignal<bool> get isLoading => _isLoading.readonly();
  ReadonlySignal<bool> get isSendingMessage => _isSendingMessage.readonly();
  ReadonlySignal<String?> get error => _error.readonly();
  ReadonlySignal<String> get typingMessage => _typingMessage.readonly();

  // Computed
  late final ReadonlySignal<List<ChatConversation>> sortedConversations =
      computed(() {
        final sorted = List<ChatConversation>.from(_conversations.value);
        sorted.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        return sorted;
      });

  late final ReadonlySignal<int> unreadCount = computed(() {
    return _conversations.value.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  });

  late final ReadonlySignal<bool> canSendMessage = computed(() {
    return _typingMessage.value.trim().isNotEmpty && !_isSendingMessage.value;
  });

  // Actions
  Future<void> loadConversations() async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      final conversationList = await _getConversationsUseCase.call(NoParams());
      _conversations.value = conversationList;
    } catch (e) {
      _error.value = e.toString();
      print('❌ Erro ao carregar conversas: $e'); // Debug
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startConversation(VirtualContact contact) async {
    if (_isLoading.value) return;

    print('🚀 Iniciando conversa com ${contact.name}'); // Debug

    _isLoading.value = true;
    _error.value = null;

    try {
      final conversationId =
          'conv_${contact.id}_${DateTime.now().millisecondsSinceEpoch}';

      final conversation = await _startConversationUseCase.call(
        StartConversationParams(
          conversationId: conversationId,
          contactId: contact.id,
          contactName: contact.name,
          contactProfileImage: contact.profileImage,
          language: contact.language,
        ),
      );

      // Add to conversations if not already there
      if (!_conversations.value.any((c) => c.id == conversation.id)) {
        _conversations.value = [..._conversations.value, conversation];
      }

      _currentConversation.value = conversation;
      await loadMessages(conversation.id);

      print('✅ Conversa iniciada: ${conversation.id}'); // Debug
    } catch (e) {
      _error.value = e.toString();
      print('❌ Erro ao iniciar conversa: $e'); // Debug
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final messageList = await _getMessagesUseCase.call(
        GetMessagesParams(conversationId),
      );
      _messages.value = messageList;
      print('📱 ${messageList.length} mensagens carregadas'); // Debug
    } catch (e) {
      _error.value = e.toString();
      print('❌ Erro ao carregar mensagens: $e'); // Debug
    }
  }

  Future<void> sendMessage(String content, VirtualContact contact) async {
    if (_isSendingMessage.value || content.trim().isEmpty) {
      print(
        '⚠️ Não pode enviar: isSending=${_isSendingMessage.value}, content="${content.trim()}"',
      ); // Debug
      return;
    }

    final conversation = _currentConversation.value;
    if (conversation == null) {
      print('❌ Conversa não encontrada'); // Debug
      return;
    }

    print(
      '📤 Enviando mensagem para IA: "$content" (${contact.language})',
    ); // Debug

    _isSendingMessage.value = true;
    _error.value = null;

    try {
      final userMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversation.id,
        senderId: 'user',
        content: content.trim(),
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isFromUser: true,
      );

      // Add user message immediately
      final currentMessages = List<ChatMessage>.from(_messages.value);
      currentMessages.add(userMessage);
      _messages.value = currentMessages;
      _typingMessage.value = '';

      print('✅ Mensagem do usuário adicionada'); // Debug

      // Use the real AI service via use case
      try {
        print('🤖 Chamando IA real...'); // Debug

        await _sendMessageUseCase.call(
          SendMessageParams(
            message: userMessage,
            contactId: contact.id,
            language: contact.language,
          ),
        );

        print('✅ IA processou a mensagem'); // Debug

        // Reload messages to get AI response and any moderator tips
        await loadMessages(conversation.id);
      } catch (aiError) {
        print('❌ Erro na IA real, usando fallback: $aiError'); // Debug

        // Fallback to simple response if AI fails
        final fallbackResponse = _generateSimpleFallback(
          conversation.id,
          contact.language,
        );

        final updatedMessages = List<ChatMessage>.from(_messages.value);
        updatedMessages.add(fallbackResponse);
        _messages.value = updatedMessages;

        // Show error to user
        _error.value =
            'IA temporariamente indisponível. Usando resposta básica.';
      }
    } catch (e) {
      print('❌ Erro geral ao enviar mensagem: $e'); // Debug
      _error.value = e.toString();

      // Remove the failed message from the list
      final messageList = List<ChatMessage>.from(_messages.value);
      if (messageList.isNotEmpty &&
          messageList.last.isFromUser &&
          messageList.last.status == MessageStatus.sending) {
        messageList.removeLast();
        _messages.value = messageList;
      }
    } finally {
      _isSendingMessage.value = false;
    }
  }

  // Simplified fallback response generator
  ChatMessage _generateSimpleFallback(String conversationId, String language) {
    final responses = {
      'Português': [
        'Desculpe, estou com problema técnico. Como posso ajudá-lo?',
        'Houve um erro, mas vamos continuar. O que você gostaria de praticar?',
        'Problema temporário. Que tal continuarmos nossa conversa?',
      ],
      'Inglês': [
        'Sorry, I\'m having technical issues. How can I help you?',
        'There was an error, but let\'s continue. What would you like to practice?',
        'Temporary problem. How about we continue our conversation?',
      ],
      'Espanhol': [
        'Disculpa, tengo un problema técnico. ¿Cómo puedo ayudarte?',
        'Hubo un error, pero continuemos. ¿Qué te gustaría practicar?',
        'Problema temporal. ¿Qué tal si continuamos nuestra conversación?',
      ],
    };

    final languageResponses = responses[language] ?? responses['Português']!;
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % languageResponses.length;

    return ChatMessage(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: 'ai_contact',
      content: languageResponses[randomIndex],
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
    );
  }

  // ADICIONE também este método atualizado para áudio
  Future<void> sendAudioMessage(
    String audioPath,
    VirtualContact contact,
  ) async {
    if (_isSendingMessage.value) return;

    final conversation = _currentConversation.value;
    if (conversation == null) return;

    print('🎵 Enviando mensagem de áudio para IA'); // Debug

    _isSendingMessage.value = true;
    _error.value = null;

    try {
      final audioMessage = ChatMessage(
        id: 'audio_msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversation.id,
        senderId: 'user',
        content: 'Mensagem de áudio enviada',
        type: MessageType.audio,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        audioPath: audioPath,
        isFromUser: true,
      );

      // Add message optimistically
      final currentMessages = List<ChatMessage>.from(_messages.value);
      currentMessages.add(audioMessage);
      _messages.value = currentMessages;

      try {
        // Use real AI service for audio
        await _sendAudioMessageUseCase.call(
          SendAudioMessageParams(
            message: audioMessage,
            audioPath: audioPath,
            contactId: contact.id,
            language: contact.language,
          ),
        );

        // Reload messages to get transcription and AI response
        await loadMessages(conversation.id);
      } catch (aiError) {
        print('❌ Erro na IA para áudio: $aiError'); // Debug

        // Fallback response
        final fallbackResponse = _generateSimpleFallback(
          conversation.id,
          contact.language,
        );
        final updatedMessages = List<ChatMessage>.from(_messages.value);
        updatedMessages.add(fallbackResponse);
        _messages.value = updatedMessages;
      }
    } catch (e) {
      print('❌ Erro ao enviar áudio: $e'); // Debug
      _error.value = e.toString();
    } finally {
      _isSendingMessage.value = false;
    }
  }

  void setCurrentConversation(ChatConversation conversation) {
    _currentConversation.value = conversation;
    loadMessages(conversation.id);
  }

  void updateTypingMessage(String message) {
    _typingMessage.value = message;
  }

  void clearError() {
    _error.value = null;
  }

  void clearCurrentConversation() {
    _currentConversation.value = null;
    _messages.value = [];
    _typingMessage.value = '';
  }

  // Simplified AI response generator
  ChatMessage _generateAIResponse(
    String conversationId,
    String language,
    String userMessage,
  ) {
    final responses = {
      'Português': [
        'Olá! Como você está?',
        'Muito interessante! Continue.',
        'Excelente! Vamos praticar mais.',
        'Ótimo progresso no português!',
      ],
      'Inglês': [
        'Hello! How are you?',
        'Very interesting! Please continue.',
        'Excellent! Let\'s practice more.',
        'Great progress in English!',
      ],
      'Espanhol': [
        '¡Hola! ¿Cómo estás?',
        '¡Muy interesante! Continúa.',
        '¡Excelente! Practiquemos más.',
        '¡Gran progreso en español!',
      ],
      'Francês': [
        'Bonjour! Comment allez-vous?',
        'Très intéressant! Continuez.',
        'Excellent! Pratiquons plus.',
        'Excellent progrès en français!',
      ],
      'Alemão': [
        'Hallo! Wie geht es Ihnen?',
        'Sehr interessant! Weiter so.',
        'Ausgezeichnet! Mehr üben.',
        'Großer Fortschritt auf Deutsch!',
      ],
      'Italiano': [
        'Ciao! Come stai?',
        'Molto interessante! Continua.',
        'Eccellente! Pratichiamo di più.',
        'Ottimo progresso in italiano!',
      ],
    };

    final languageResponses = responses[language] ?? responses['Português']!;
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % languageResponses.length;

    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: 'ai_contact',
      content: languageResponses[randomIndex],
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
    );
  }

  ChatMessage _generateModeratorTip(String conversationId, String language) {
    final tips = {
      'Português': [
        '💡 Dica: Use mais conectivos para soar natural.',
        '💡 Dica: Pratique a pronúncia das palavras.',
      ],
      'Inglês': [
        '💡 Tip: Try using contractions like "I\'m".',
        '💡 Tip: Practice pronunciation of difficult sounds.',
      ],
      'Espanhol': [
        '💡 Consejo: Practica "ser" vs "estar".',
        '💡 Consejo: Usa expresiones idiomáticas.',
      ],
    };

    final languageTips = tips[language] ?? tips['Português']!;
    final randomTip = languageTips[DateTime.now().second % languageTips.length];

    return ChatMessage(
      id: 'mod_tip_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: 'moderator',
      senderName: 'Moderador IA',
      content: randomTip,
      type: MessageType.moderatorTip,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
      isModerator: true,
    );
  }

  void forceCreateConversation(VirtualContact contact) {
    print('🔧 Forçando criação de conversa para ${contact.name}'); // Debug

    final conversationId =
        'conv_${contact.id}_${DateTime.now().millisecondsSinceEpoch}';

    final conversation = ChatConversation(
      id: conversationId,
      contactId: contact.id,
      contactName: contact.name,
      contactProfileImage: contact.profileImage,
      language: contact.language,
      messages: [],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    // Set current conversation directly
    _currentConversation.value = conversation;
    _messages.value = [];

    // Add to conversations list if not already there
    if (!_conversations.value.any((c) => c.contactId == contact.id)) {
      _conversations.value = [..._conversations.value, conversation];
    }

    print('✅ Conversa forçada criada: $conversationId'); // Debug
  }

  // Método simplificado para debug
  void debugCurrentState() {
    print('🔍 Estado atual:');
    print('  - Conversa atual: ${_currentConversation.value?.id ?? "null"}');
    print('  - Total conversas: ${_conversations.value.length}');
    print('  - Total mensagens: ${_messages.value.length}');
    print('  - Está enviando: ${_isSendingMessage.value}');
    print('  - Carregando: ${_isLoading.value}');
    print('  - Erro: ${_error.value ?? "nenhum"}');
  }
}
