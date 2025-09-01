import 'package:flutter/material.dart';
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
    widget.chatSignals.startConversation(widget.contact);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
          // Messages area
          Expanded(
            child: Watch((context) {
              final messages = widget.chatSignals.messages.value;

              // Auto-scroll when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

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
