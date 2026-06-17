import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/game_model.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GameModel>> getGames() {
    return _firestore
        .collection('games')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> seedSampleGames() async {
    final games = _firestore.collection('games');
    final existing = await games.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final sampleGames = [
      {
        'id': 'game_1',
        'hostId': 'sample_host',
        'hostName': 'Rahul S',
        'sport': 'Badminton',
        'venue': 'Decathlon Sports Centre, Hinjawadi',
        'dateTime': now.add(const Duration(hours: 3)).toIso8601String(),
        'totalPlayersNeeded': 4,
        'joinedPlayerIds': ['sample_host'],
        'skillLevel': 'Intermediate',
        'notes': 'Bring your own racket',
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 'game_2',
        'hostId': 'sample_host2',
        'hostName': 'Priya M',
        'sport': 'Football',
        'venue': 'Wakad Football Ground',
        'dateTime': now.add(const Duration(days: 1)).toIso8601String(),
        'totalPlayersNeeded': 10,
        'joinedPlayerIds': ['sample_host2', 'player_2', 'player_3'],
        'skillLevel': 'Beginner',
        'notes': 'Evening game, bring water',
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 'game_3',
        'hostId': 'sample_host3',
        'hostName': 'Amit K',
        'sport': 'Cricket',
        'venue': 'Baner Cricket Academy',
        'dateTime': now.add(const Duration(days: 2)).toIso8601String(),
        'totalPlayersNeeded': 11,
        'joinedPlayerIds': ['sample_host3', 'player_4'],
        'skillLevel': 'Advanced',
        'notes': null,
        'createdAt': now.toIso8601String(),
      },
    ];

    for (final game in sampleGames) {
      await games.doc(game['id'] as String).set(game);
    }
  }
}