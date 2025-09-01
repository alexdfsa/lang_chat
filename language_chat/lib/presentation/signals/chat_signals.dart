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
  late final sortedConversations = computed(() {
    final sorted = List<ChatConversation>.from(_conversations.value);
    sorted.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return sorted;
  });

  late final unreadCount = computed(() {
    return _conversations.value.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  });

  late final canSendMessage = computed(() {
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
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startConversation(VirtualContact contact) async {
    if (_isLoading.value) return;

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
    } catch (e) {
      _error.value = e.toString();
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
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> sendMessage(String content, VirtualContact contact) async {
    if (_isSendingMessage.value || content.trim().isEmpty) return;

    final conversation = _currentConversation.value;
    if (conversation == null) return;

    _isSendingMessage.value = true;
    _error.value = null;

    try {
      final message = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversation.id,
        senderId: 'user',
        content: content.trim(),
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isFromUser: true,
      );

      // Add message optimistically
      _messages.value = [..._messages.value, message];
      _typingMessage.value = '';

      await _sendMessageUseCase.call(
        SendMessageParams(
          message: message,
          contactId: contact.id,
          language: contact.language,
        ),
      );

      // Reload messages to get AI response and any moderator tips
      await loadMessages(conversation.id);
    } catch (e) {
      _error.value = e.toString();
      // Remove the failed message from the list
      _messages.value = _messages.value
          .where((m) => m.id != 'msg_${DateTime.now().millisecondsSinceEpoch}')
          .toList();
    } finally {
      _isSendingMessage.value = false;
    }
  }

  Future<void> sendAudioMessage(
    String audioPath,
    VirtualContact contact,
  ) async {
    if (_isSendingMessage.value) return;

    final conversation = _currentConversation.value;
    if (conversation == null) return;

    _isSendingMessage.value = true;
    _error.value = null;

    try {
      final message = ChatMessage(
        id: 'audio_msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversation.id,
        senderId: 'user',
        content: 'Áudio enviado...',
        type: MessageType.audio,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        audioPath: audioPath,
        isFromUser: true,
      );

      // Add message optimistically
      _messages.value = [..._messages.value, message];

      await _sendAudioMessageUseCase.call(
        SendAudioMessageParams(
          message: message,
          audioPath: audioPath,
          contactId: contact.id,
          language: contact.language,
        ),
      );

      // Reload messages to get the transcription and AI response
      await loadMessages(conversation.id);
    } catch (e) {
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
}
