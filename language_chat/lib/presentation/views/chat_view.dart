import 'package:flutter/material.dart';
import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/presentation/signals/audio_signals.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/widgets/chat_app_bar.dart';
import 'package:langchat/presentation/widgets/message_input_widget.dart';
import 'package:langchat/presentation/widgets/message_list_widget.dart';
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
    // Usar o UseCase para iniciar a conversa de forma correta.
    // Isso vai buscar uma conversa existente ou criar uma nova,
    // garantindo que o histórico não seja misturado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.chatSignals.startConversation(widget.contact);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.chatSignals.resetCurrentConversation();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Com a lista invertida, o "final" da lista está na posição 0.0
          _scrollController.animateTo(
            0.0,
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
        onBack: () {
          widget.chatSignals.resetCurrentConversation();
          Navigator.pop(context);
        },
        onActionSelected: (action) => _handleMenuAction(context, action),
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

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear_chat':
        _showClearChatDialog(context);
        break;
      case 'contact_info':
        Navigator.pushNamed(
          context,
          '/contact-details',
          arguments: widget.contact,
        );
        break;
      case 'block':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade de bloqueio será implementada'),
          ),
        );
        break;
    }
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa?'),
        content: const Text(
          'Todas as mensagens desta conversa serão apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              widget.chatSignals.clearCurrentConversation();
              Navigator.pop(context);
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
