import 'package:flutter/material.dart';
import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';
import 'package:signals/signals_flutter.dart';

class ContactListWidget extends StatelessWidget {
  final ContactSignals contactSignals;
  final ChatSignals chatSignals;

  const ContactListWidget({
    super.key,
    required this.contactSignals,
    required this.chatSignals,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final contacts = contactSignals.contacts.value;
      final isLoading = contactSignals.isLoading.value;
      final error = contactSignals.error.value;

      if (isLoading && contacts.isEmpty) {
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
                'Erro ao carregar contatos',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  contactSignals.clearError();
                  contactSignals.loadContacts();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }

      if (contacts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhum contato criado',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no + para criar seu primeiro contato virtual',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => contactSignals.loadContacts(),
        color: const Color(0xFF128C7E),
        child: ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return ContactTile(
              contact: contact,
              onTap: () => _navigateToContactDetails(context, contact),
              onChatTap: () => _startChat(context, contact),
            );
          },
        ),
      );
    });
  }

  void _navigateToContactDetails(BuildContext context, VirtualContact contact) {
    Navigator.pushNamed(context, '/contact-details', arguments: contact);
  }

  void _startChat(BuildContext context, VirtualContact contact) async {
    await chatSignals.startConversation(contact);

    if (context.mounted) {
      Navigator.pushNamed(context, '/chat', arguments: contact);
    }
  }
}

class ContactTile extends StatelessWidget {
  final VirtualContact contact;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: contact.isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${contact.language} • ${contact.nationality}'),
            const SizedBox(height: 2),
            Text(
              contact.temperament,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat, color: Color(0xFF128C7E)),
          onPressed: onChatTap,
        ),
        onTap: onTap,
      ),
    );
  }
}
