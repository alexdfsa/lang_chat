// lib/core/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:langchat/core/ai_factory.dart';
import 'package:langchat/data/repositories/flutter_sound_audio_repository.dart';
import 'package:langchat/data/repositories/local_chat_repository.dart';
import 'package:langchat/data/repositories/local_contact_repository.dart';
import 'package:langchat/domain/repositories/ai_service_repository.dart';
import 'package:langchat/domain/repositories/audio_repository.dart';
import 'package:langchat/domain/repositories/chat_repository.dart';
import 'package:langchat/domain/repositories/contact_repository.dart';
import 'package:langchat/domain/usecases/chat_usecases.dart';
import 'package:langchat/domain/usecases/contact_usecases.dart';
import 'package:langchat/presentation/signals/audio_signals.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  print('🚀 Configurando injeção de dependências...'); // Debug

  // Repositories - criar e inicializar instâncias
  final localContactRepo = LocalContactRepository();
  final localChatRepo = LocalChatRepository();
  final audioRepo = FlutterSoundAudioRepository();

  // Inicializar repositórios que precisam
  await localContactRepo.init();
  await localChatRepo.init();
  await audioRepo.init();

  // Registrar repositórios
  getIt.registerSingleton<ContactRepository>(localContactRepo);
  getIt.registerSingleton<ChatRepository>(localChatRepo);
  getIt.registerSingleton<AudioRepository>(audioRepo);

  // AI Service - usar factory para escolher implementação
  getIt.registerSingleton<AIServiceRepository>(AIFactory.createAIService());

  // Use Cases - Contacts
  getIt.registerLazySingleton(
    () => GetAllContactsUseCase(getIt<ContactRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateContactUseCase(getIt<ContactRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateContactUseCase(getIt<ContactRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteContactUseCase(
      getIt<ContactRepository>(),
      getIt<ChatRepository>(),
    ),
  );

  // Use Cases - Chat
  getIt.registerLazySingleton(
    () => StartConversationUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => SendMessageUseCase(
      getIt<ChatRepository>(),
      getIt<AIServiceRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => SendAudioMessageUseCase(
      getIt<ChatRepository>(),
      getIt<AIServiceRepository>(),
      getIt<SendMessageUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetConversationsUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetMessagesUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => ClearConversationUseCase(getIt<ChatRepository>()),
  );

  // Signals
  getIt.registerLazySingleton(
    () => ContactSignals(
      getAllContactsUseCase: getIt<GetAllContactsUseCase>(),
      createContactUseCase: getIt<CreateContactUseCase>(),
      updateContactUseCase: getIt<UpdateContactUseCase>(),
      deleteContactUseCase: getIt<DeleteContactUseCase>(),
    ),
  );

  getIt.registerLazySingleton(
    () => ChatSignals(
      startConversationUseCase: getIt<StartConversationUseCase>(),
      sendMessageUseCase: getIt<SendMessageUseCase>(),
      sendAudioMessageUseCase: getIt<SendAudioMessageUseCase>(),
      getConversationsUseCase: getIt<GetConversationsUseCase>(),
      getMessagesUseCase: getIt<GetMessagesUseCase>(),
      clearConversationUseCase: getIt<ClearConversationUseCase>(),
    ),
  );

  getIt.registerLazySingleton(
    () => AudioSignals(audioRepository: getIt<AudioRepository>()),
  );

  print('✅ Injeção de dependências configurada com sucesso'); // Debug
}
