import 'package:flutter/material.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';
import 'package:langchat/presentation/widgets/contact_list_widget.dart';
import 'package:langchat/presentation/widgets/conversation_list_widget.dart';
import 'package:langchat/presentation/widgets/floating_action_menu.dart';
import 'package:signals/signals_flutter.dart';

class HomeView extends StatefulWidget {
  final ContactSignals contactSignals;
  final ChatSignals chatSignals;

  const HomeView({
    super.key,
    required this.contactSignals,
    required this.chatSignals,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    widget.contactSignals.loadContacts();
    widget.chatSignals.loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Chat'),
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Conversas',
              icon: Watch((context) {
                final unreadCount = widget.chatSignals.unreadCount.value;
                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.chat),
                );
              }),
            ),
            Tab(
              text: 'Contatos',
              icon: Watch((context) {
                final contactsCount =
                    widget.contactSignals.contacts.value.length;
                return Badge(
                  isLabelVisible: contactsCount > 0,
                  label: Text('$contactsCount'),
                  child: const Icon(Icons.people),
                );
              }),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ConversationListWidget(
            chatSignals: widget.chatSignals,
            contactSignals: widget.contactSignals,
          ),
          ContactListWidget(
            contactSignals: widget.contactSignals,
            chatSignals: widget.chatSignals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionMenu(
        contactSignals: widget.contactSignals,
        onCreateContact: () => _navigateToCreateContact(context),
      ),
    );
  }

  void _navigateToCreateContact(BuildContext context) {
    Navigator.pushNamed(context, '/create-contact');
  }
}
