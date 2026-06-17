import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/domain/game_model.dart';
import '../../../home/presentation/widgets/game_card.dart';

class JoinedGamesScreen extends ConsumerWidget {
  const JoinedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Joined Games')),
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
          final games = (snapshot.data?.docs
                      .map((d) => GameModel.fromMap(
                          d.data() as Map<String, dynamic>))
                      .where((g) => g.hostId != uid)
                      .toList() ??
                  [])
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    "You haven't joined any games yet",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Find a Game'),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) => GameCard(
              game: games[index],
              onTap: () => context.push('/game/${games[index].id}'),
            ),
          );
        },
      ),
    );
  }
}