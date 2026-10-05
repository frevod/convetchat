import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/ui/pages/chat_page.dart';
import 'package:convetchat/features/chat/ui/pages/room_info_page.dart';
import 'package:convetchat/features/chats/ui/pages/create_group_page.dart';
import 'package:convetchat/features/chats/ui/pages/room_directory_page.dart';
import 'package:convetchat/features/chats/ui/pages/user_search_page.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/pages/backup_page.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/pages/appearance_page.dart';
import 'package:convetchat/features/settings/ui/pages/chat_settings_page.dart';
import 'package:convetchat/features/settings/ui/pages/experimental_page.dart';
import 'package:convetchat/features/settings/ui/pages/feedback_page.dart';
import 'package:convetchat/features/settings/ui/pages/notifications_page.dart';
import 'package:convetchat/features/settings/ui/pages/profile_page.dart';
import 'package:convetchat/features/settings/ui/pages/security_page.dart';
import 'package:convetchat/features/settings/ui/pages/settings_page.dart';
import 'package:convetchat/features/settings/ui/pages/talker_log_page.dart';
import 'package:convetchat/features/welcome/ui/pages/splash_page.dart';
import 'package:convetchat/features/welcome/ui/pages/welcome_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import '../features/auth/ui/pages/server_page.dart';
import '../features/chats/ui/pages/chats_page.dart';
import '../features/home/ui/pages/home_page.dart';

const _guestLocations = ['/welcome', '/server_choice'];

const _publicLocations = ['/', ..._guestLocations];

class AuthRefreshListenable() extends ChangeNotifier {
  StreamSubscription<dynamic>? _loginSub;
  StreamSubscription<dynamic>? _clearSub;

  void ensureAttached() {
    if (!getIt.isReadySync<Client>()) return;
    _loginSub ??= getIt<Client>().onLoginStateChanged.stream.listen(
      (_) => notifyListeners(),
    );

    _clearSub ??= getIt<Client>().onSessionCleared.stream.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _loginSub?.cancel();
    _clearSub?.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  final authRefresh = AuthRefreshListenable();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      authRefresh.ensureAttached();
      final location = state.matchedLocation;

      if (!getIt.isReadySync<Client>()) {
        return location == '/' ? null : '/';
      }
      final loggedIn = getIt<Client>().isLogged();

      if (!loggedIn && !_publicLocations.contains(location)) {
        return '/';
      }
      if (loggedIn && (location == '/' || _guestLocations.contains(location))) {
        return '/chats';
      }
      if (loggedIn &&
          location == '/backup' &&
          state.uri.queryParameters['reset'] != 'true') {
        return _backupRedirect();
      }
      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/server_choice',
        builder: (context, state) => const ServerPage(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatPage(
          roomId: state.pathParameters['id']!,
          scrollToEventId: state.extra as String?,
        ),
        routes: [
          GoRoute(
            path: 'info',
            builder: (context, state) =>
                RoomInfoPage(roomId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/user_search',
        builder: (context, state) => const UserSearchPage(),
      ),
      GoRoute(
        path: '/create_group',
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: '/room_directory',
        builder: (context, state) => const RoomDirectoryPage(),
      ),
      GoRoute(
        path: '/talker-logs',
        builder: (context, state) => const TalkerLogPage(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) =>
            BackupPage(reset: state.uri.queryParameters['reset'] == 'true'),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (context, state) => const AppearancePage(),
      ),
      GoRoute(
        path: '/settings/chat',
        builder: (context, state) => const ChatSettingsPage(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: '/settings/experimental',
        builder: (context, state) => const ExperimentalPage(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) =>
            ProfilePage(cubit: state.extra as SettingsCubit?),
      ),
      GoRoute(
        path: '/settings/feedback',
        builder: (context, state) => const FeedbackPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<String?> _backupRedirect() async {
  try {
    final identity = await getIt<EncryptionRepository>().getIdentityState();
    if (identity.connected) return '/chats';
  } catch (_) {}
  return null;
}
