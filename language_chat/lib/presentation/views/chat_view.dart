import 'package:flutter/material.dart';
import 'package:language_chat/domain/entities/chat_conversation.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/presentation/signals/audio_signals.dart';
import 'package:language_chat/presentation/signals/chat_signals.dart';
import 'package:language_chat/presentation/widgets/chat_app_bar.dart';
import 'package:language_chat/presentation/widgets/message_input_widget.dart';
import 'package:language_chat/presentation/widgets/message_list_widget.dart';
import 'package:signals/signals_flutter.dart';

class ChatView extends StatefulWidget {
  final VirtualContact contact;
  final ChatSignals chatSignals;
  final AudioSignals audioSignals;

  const ChatView({
    super.key,
    required this.contact,
    required this.chatSignals,
    required this.audioSignals,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ensureConversationExists();
  }

  void _ensureConversationExists() {
    print(
      '🎬 Garantindo que conversa existe para ${widget.contact.name}',
    ); // Debug

    // Sempre criar uma conversa nova para garantir que funciona
    final conversationId =
        'conv_${widget.contact.id}_${DateTime.now().millisecondsSinceEpoch}';

    final conversation = ChatConversation(
      id: conversationId,
      contactId: widget.contact.id,
      contactName: widget.contact.name,
      contactProfileImage: widget.contact.profileImage,
      language: widget.contact.language,
      messages: [],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    // Usar o método setCurrentConversation que já existe
    widget.chatSignals.setCurrentConversation(conversation);

    print('✅ Conversa garantida: $conversationId'); // Debug
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        contact: widget.contact,
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Debug info (remove depois que funcionar)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green[50],
            child: Watch((context) {
              final currentConv = widget.chatSignals.currentConversation.value;
              return Text(
                'Debug: Conversa ${currentConv?.id ?? "NULA"} | Idioma: ${widget.contact.language}',
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
              );
            }),
          ),

          // Messages area
          Expanded(
            child: Watch((context) {
              final messages = widget.chatSignals.messages.value;

              // Auto-scroll when messages change
              if (messages.isNotEmpty) {
                _scrollToBottom();
              }

              return MessageListWidget(
                messages: messages,
                scrollController: _scrollController,
                audioSignals: widget.audioSignals,
              );
            }),
          ),

          // Message input area
          MessageInputWidget(
            contact: widget.contact,
            chatSignals: widget.chatSignals,
            audioSignals: widget.audioSignals,
          ),
        ],
      ),
    );
  }
}
