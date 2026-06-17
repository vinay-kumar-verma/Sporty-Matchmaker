import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/domain/game_model.dart';

class AllChatsScreen extends ConsumerWidget {
  const AllChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .where('joinedPlayerIds', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final games = snapshot.data?.docs
                  .map((d) =>
                      GameModel.fromMap(d.data() as Map<String, dynamic>))
                  .toList() ??
              [];
          if (games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Join a game to chat with your co-players',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return ListTile(
                onTap: () => context.push(
                  '/chat/${game.id}?name=${Uri.encodeComponent(game.sport)}',
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      _emojiForSport(game.sport),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                title: Text(
                  game.sport,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  game.venue,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              );
            },
          );
        },
      ),
    );
  }

  String _emojiForSport(String sport) {
    const emojis = {
      'Badminton': '🏸',
      'Cricket': '🏏',
      'Football': '⚽',
      'Tennis': '🎾',
      'Basketball': '🏀',
      'Volleyball': '🏐',
      'Swimming': '🏊',
      'Table Tennis': '🏓',
      'Cycling': '🚴',
      'Running': '🏃',
    };
    return emojis[sport] ?? '🏅';
  }
}