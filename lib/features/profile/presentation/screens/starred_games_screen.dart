import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/domain/game_model.dart';
import '../../../home/presentation/widgets/game_card.dart';

class StarredGamesScreen extends ConsumerWidget {
  const StarredGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Starred Games')),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (user) {
          if (user == null || user.starredGameIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'No starred games yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Star a game from its detail page\nto find it quickly later',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .where(FieldPath.documentId,
                    whereIn: user.starredGameIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                );
              }
              final games = snapshot.data?.docs
                      .map((d) => GameModel.fromMap(
                          d.data() as Map<String, dynamic>))
                      .toList() ??
                  [];

              if (games.isEmpty) {
                return const Center(
                  child: Text(
                    'Starred games no longer available',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: games.length,
                itemBuilder: (context, index) => GameCard(
                  game: games[index],
                  onTap: () =>
                      context.push('/game/${games[index].id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}