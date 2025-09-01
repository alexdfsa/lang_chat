import 'package:go_router/go_router.dart';
import 'package:language_chat/core/dependency_injection.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/presentation/views/chat_view.dart';
import 'package:language_chat/presentation/views/contact_details_view.dart';
import 'package:language_chat/presentation/views/create_contact_view.dart';
import 'package:language_chat/presentation/views/home_view.dart' show HomeView;

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) =>
          HomeView(contactSignals: getIt(), chatSignals: getIt()),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) {
        final contact = state.extra as VirtualContact;
        return ChatView(
          contact: contact,
          chatSignals: getIt(),
          audioSignals: getIt(),
        );
      },
    ),
    GoRoute(
      path: '/create-contact',
      name: 'create-contact',
      builder: (context, state) {
        final editingContact = state.extra as VirtualContact?;
        return CreateContactView(
          contactSignals: getIt(),
          editingContact: editingContact,
        );
      },
    ),
    GoRoute(
      path: '/contact-details',
      name: 'contact-details',
      builder: (context, state) {
        final contact = state.extra as VirtualContact;
        return ContactDetailsView(
          contact: contact,
          contactSignals: getIt(),
          chatSignals: getIt(),
        );
      },
    ),
  ],
);
