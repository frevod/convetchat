import 'package:convetchat/app/router.dart';
import 'package:convetchat/core/firebase/telemetry_service.dart';
import 'package:convetchat/core/logging/matrix_talker_bridge.dart';
import 'package:convetchat/core/logging/talker.dart';
import 'package:convetchat/core/matrix/client_factory.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/push/push_service.dart';
import 'package:convetchat/core/telegram/telegram_feedback_service.dart';
import 'package:convetchat/core/theme/accent_color_store.dart';
import 'package:convetchat/core/theme/theme_mode_store.dart';
import 'package:convetchat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:convetchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:convetchat/features/auth/ui/bloc/auth_cubit.dart';
import 'package:convetchat/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/domain/services/circle_playback_coordinator.dart';
import 'package:convetchat/features/chat/domain/services/circle_video_service.dart';
import 'package:convetchat/features/chat/domain/services/voice_playback_service.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:convetchat/features/chats/data/repositories/chats_repository_impl.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/chats_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/chat_search_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/user_search_cubit.dart';
import 'package:convetchat/features/encryption/data/repositories/encryption_repository_impl.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final talker = createTalker();
  attachMatrixLogsToTalker(talker);

  getIt
    ..registerLazySingleton<Talker>(() => talker)
    ..registerLazySingleton<PlatformStyle>(platformStyle)
    ..registerLazySingleton<ThemeModeStore>(() => ThemeModeStore())
    ..registerLazySingleton<AccentColorStore>(() => AccentColorStore())
    ..registerLazySingleton<TelemetryService>(
      () => TelemetryService(getIt<Talker>()),
    )
    ..registerLazySingleton<TelegramFeedbackService>(
      () => TelegramFeedbackService(getIt<Talker>()),
    )
    ..registerLazySingleton<GoRouter>(createRouter)
    ..registerLazySingletonAsync<Client>(ClientFactory.createClient)
    ..registerLazySingleton<PushService>(
      () => PushService(getIt<Client>(), getIt<Talker>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<Client>()),
    )
    ..registerLazySingleton<EncryptionRepository>(
      () => EncryptionRepositoryImpl(getIt<Client>()),
    )
    ..registerLazySingleton<ChatsRepository>(
      () => ChatsRepositoryImpl(getIt<Client>()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(getIt<Client>()),
    )
    ..registerLazySingleton<VoicePlaybackService>(() => VoicePlaybackService())
    ..registerLazySingleton<CircleVideoService>(() => CircleVideoService())
    ..registerLazySingleton<CirclePlaybackCoordinator>(
      () => CirclePlaybackCoordinator(),
    )
    ..registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()))
    ..registerFactoryParam<EncryptionCubit, bool, void>(
      (reset, _) =>
          EncryptionCubit(getIt<EncryptionRepository>(), reset: reset),
    )
    ..registerFactory<SettingsCubit>(
      () =>
          SettingsCubit(getIt<AuthRepository>(), getIt<EncryptionRepository>()),
    )
    ..registerFactory<FeedbackCubit>(
      () => FeedbackCubit(getIt<TelegramFeedbackService>()),
    )
    ..registerFactory<ChatsCubit>(() => ChatsCubit(getIt<ChatsRepository>()))
    ..registerFactory<ChatSearchCubit>(
      () => ChatSearchCubit(getIt<ChatsRepository>()),
    )
    ..registerFactory<UserSearchCubit>(
      () => UserSearchCubit(getIt<ChatsRepository>()),
    )
    ..registerFactory<CreateGroupCubit>(
      () => CreateGroupCubit(getIt<ChatsRepository>()),
    )
    ..registerFactoryParam<ChatCubit, String, void>(
      (roomId, _) => ChatCubit(getIt<ChatRepository>(), roomId: roomId),
    )
    ..registerFactoryParam<RoomInfoCubit, String, void>(
      (roomId, _) => RoomInfoCubit(getIt<ChatRepository>(), roomId: roomId),
    );
}
