import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:langchat/domain/entities/chat_conversation.dart';
import 'package:langchat/domain/entities/chat_message.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';
import 'package:signals/signals_flutter.dart';

class ConversationListWidget extends StatelessWidget {
  final ChatSignals chatSignals;
  final ContactSignals contactSignals;

  const ConversationListWidget({
    super.key,
    required this.chatSignals,
    required this.contactSignals,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final conversations = chatSignals.sortedConversations.value;
      final isLoading = chatSignals.isLoading.value;
      final error = chatSignals.error.value;

      if (isLoading && conversations.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF128C7E)),
        );
      }

      if (error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar conversas',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  chatSignals.clearError();
                  chatSignals.loadConversations();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }

      if (conversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma conversa ainda',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Vá para a aba Contatos e inicie uma conversa',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => chatSignals.loadConversations(),
        color: const Color(0xFF128C7E),
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () => _openConversation(context, conversation),
            );
          },
        ),
      );
    });
  }

  void _openConversation(
    BuildContext context,
    ChatConversation conversation,
  ) async {
    // Find the contact
    final contacts = contactSignals.contacts.value;
    final contact = contacts.firstWhere(
      (c) => c.id == conversation.contactId,
      orElse: () => throw Exception('Contact not found'),
    );

    chatSignals.setCurrentConversation(conversation);

    if (context.mounted) {
      Navigator.pushNamed(context, '/chat', arguments: contact);
    }
  }
}

class ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
            if (conversation.unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          conversation.contactName,
          style: TextStyle(
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            if (lastMessage != null) ...[
              if (lastMessage.isModerator)
                const Icon(Icons.lightbulb, size: 16, color: Colors.orange),
              if (lastMessage.type == MessageType.audio)
                const Icon(Icons.mic, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getLastMessagePreview(lastMessage),
                  style: TextStyle(
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: lastMessage.isModerator ? Colors.orange[700] : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Text('Sem mensagens'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? const Color(0xFF128C7E)
                    : Colors.grey,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.language,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _getLastMessagePreview(ChatMessage message) {
    if (message.isModerator) {
      return message.content;
    }

    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.audio:
        return '🎵 Mensagem de áudio';
      case MessageType.system:
        return message.content;
      case MessageType.moderatorTip:
        return message.content;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE', 'pt_BR').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}
