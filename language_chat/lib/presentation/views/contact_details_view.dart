import 'package:flutter/material.dart';
import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';

class ContactDetailsView extends StatelessWidget {
  final VirtualContact contact;
  final ContactSignals contactSignals;
  final ChatSignals chatSignals;

  const ContactDetailsView({
    super.key,
    required this.contact,
    required this.contactSignals,
    required this.chatSignals,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: const Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(context, value),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with profile image and basic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF128C7E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: contact.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contact.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact details cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoCard('Informações Pessoais', [
                    _buildInfoRow('Idade', '${contact.age} anos', Icons.cake),
                    _buildInfoRow('Gênero', contact.gender, Icons.person),
                    _buildInfoRow(
                      'Nacionalidade',
                      contact.nationality,
                      Icons.flag,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  _buildInfoCard('Idioma e Personalidade', [
                    _buildInfoRow('Idioma', contact.language, Icons.language),
                    _buildInfoRow(
                      'Temperamento',
                      contact.temperament,
                      Icons.mood,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  _buildInfoCard('Descrição', [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        contact.description,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _startChat(context),
          icon: const Icon(Icons.chat),
          label: const Text('Iniciar Conversa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF128C7E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF128C7E),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF128C7E), size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, '/create-contact', arguments: contact);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Contato'),
        content: Text('Tem certeza que deseja excluir ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await contactSignals.deleteContact(contact.id);
              // Recarrega a lista de conversas para refletir a exclusão
              await chatSignals.loadConversations();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context) async {
    await chatSignals.startConversation(contact);

    if (context.mounted) {
      Navigator.pushNamed(context, '/chat', arguments: contact);
    }
  }
}
