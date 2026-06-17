import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/chat/presentation/screens/all_chats_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/game/presentation/screens/create_game_screen.dart';
import '../../features/game/presentation/screens/game_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/joined_games_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/starred_games_screen.dart';
import '../../features/profile/presentation/screens/your_games_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuth = state.matchedLocation == '/' ||
          state.matchedLocation == '/otp';
      if (isLoggedIn && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) =>
            const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-game',
        builder: (context, state) =>
            const CreateGameScreen(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) => GameDetailScreen(
          gameId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          gameId: state.pathParameters['id']!,
          gameName:
              state.uri.queryParameters['name'] ?? 'Game',
        ),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const AllChatsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/your-games',
        builder: (context, state) => const YourGamesScreen(),
      ),
      GoRoute(
        path: '/joined-games',
        builder: (context, state) =>
            const JoinedGamesScreen(),
      ),
      GoRoute(
        path: '/starred-games',
        builder: (context, state) =>
            const StarredGamesScreen(),
      ),
    ],
  );
});