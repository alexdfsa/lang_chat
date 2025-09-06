import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:langchat/core/hive_cleanup_helper.dart';

import 'core/dependency_injection.dart';
import 'domain/entities/virtual_contact.dart';
import 'presentation/views/chat_view.dart';
import 'presentation/views/contact_details_view.dart';
import 'presentation/views/create_contact_view.dart';
import 'presentation/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize date formatting for Portuguese
  await initializeDateFormatting('pt_BR', null);

  // Clean up corrupted data from Hive
  await HiveCleanupHelper.cleanupCorruptedData();

  // Setup dependency injection
  await setupDependencyInjection();

  runApp(const LanguageChatApp());
}

class LanguageChatApp extends StatelessWidget {
  const LanguageChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Chat',
      debugShowCheckedModeBanner: false,
      home: HomeView(contactSignals: getIt(), chatSignals: getIt()),
      routes: {
        '/home': (context) =>
            HomeView(contactSignals: getIt(), chatSignals: getIt()),
        '/chat': (context) {
          final contact =
              ModalRoute.of(context)!.settings.arguments as VirtualContact;
          return ChatView(
            contact: contact,
            chatSignals: getIt(),
            audioSignals: getIt(),
          );
        },
        '/create-contact': (context) {
          final editingContact =
              ModalRoute.of(context)?.settings.arguments as VirtualContact?;
          return CreateContactView(
            contactSignals: getIt(),
            editingContact: editingContact,
          );
        },
        '/contact-details': (context) {
          final contact =
              ModalRoute.of(context)!.settings.arguments as VirtualContact;
          return ContactDetailsView(
            contact: contact,
            contactSignals: getIt(),
            chatSignals: getIt(),
          );
        },
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF128C7E),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFF128C7E),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF128C7E),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF128C7E), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF128C7E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        useMaterial3: true,
      ),
    );
  }
}
