// lib/features/game/data/game_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../home/domain/game_model.dart';

class CreateGameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<GameModel?> _getConflictingGame({
    required String userId,
    required DateTime dateTime,
    String? excludeGameId,
  }) async {
    final start = dateTime;
    final end = dateTime.add(const Duration(hours: 2));

    final snapshot = await _firestore
        .collection('games')
        .where('joinedPlayerIds', arrayContains: userId)
        .get();

    for (final doc in snapshot.docs) {
      final game = GameModel.fromMap(doc.data());
      if (excludeGameId != null && game.id == excludeGameId) {
        continue;
      }
      final gameStart = game.dateTime;
      final gameEnd = game.dateTime.add(const Duration(hours: 2));
      if (start.isBefore(gameEnd) && end.isAfter(gameStart)) {
        return game;
      }
    }
    return null;
  }

  // Public method for checking conflicts (used in edit time)
  Future<GameModel?> checkConflict({
    required String userId,
    required DateTime dateTime,
    String? excludeGameId,
  }) async {
    return _getConflictingGame(
      userId: userId,
      dateTime: dateTime,
      excludeGameId: excludeGameId,
    );
  }

  Future<String?> createGame({
    required String hostId,
    required String hostName,
    required String sport,
    required String venue,
    required DateTime dateTime,
    required int totalPlayersNeeded,
    required String skillLevel,
    String? notes,
  }) async {
    // Integrity guard: never allow a game in the past, regardless of caller.
    if (dateTime.isBefore(DateTime.now())) {
      return 'Game time cannot be in the past. Please pick a future date and time.';
    }

    final conflict = await _getConflictingGame(
      userId: hostId,
      dateTime: dateTime,
    );
    if (conflict != null) {
      return 'You already have a game (${conflict.sport} at ${conflict.venue}) at this time. Choose a different time.';
    }

    final id = _uuid.v4();
    final game = GameModel(
      id: id,
      hostId: hostId,
      hostName: hostName,
      sport: sport,
      venue: venue,
      dateTime: dateTime,
      totalPlayersNeeded: totalPlayersNeeded,
      joinedPlayerIds: [hostId],
      skillLevel: skillLevel,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('games').doc(id).set(game.toMap());
    return null;
  }

  Future<String?> joinGame({
    required String gameId,
    required String userId,
    required DateTime gameDateTime,
  }) async {
    // The schedule-conflict check runs first and OUTSIDE the transaction:
    // it queries across all of the user's games, and Firestore transactions
    // can only read individual documents, not run queries.
    final conflict = await _getConflictingGame(
      userId: userId,
      dateTime: gameDateTime,
      excludeGameId: gameId,
    );
    if (conflict != null) {
      return 'You are already playing ${conflict.sport} at ${conflict.venue} at this time.';
    }

    final gameRef = _firestore.collection('games').doc(gameId);

    try {
      return await _firestore.runTransaction<String?>((transaction) async {
        final snapshot = await transaction.get(gameRef);

        if (!snapshot.exists) {
          return 'This game no longer exists.';
        }

        final game = GameModel.fromMap(snapshot.data()!);

        // Already in the game — nothing to do, treat as success.
        if (game.joinedPlayerIds.contains(userId)) {
          return null;
        }

        // Atomic capacity check — this is the race-condition fix. Because
        // runTransaction re-reads and retries on any concurrent write to this
        // document, two users can no longer both grab the final spot.
        if (game.joinedPlayerIds.length >= game.totalPlayersNeeded) {
          return 'This game just filled up. Try another one.';
        }

        transaction.update(gameRef, {
          'joinedPlayerIds': FieldValue.arrayUnion([userId]),
        });

        return null;
      });
    } catch (e) {
      return 'Could not join the game. Check your connection and try again.';
    }
  }

  Future<void> leaveGame({
    required String gameId,
    required String userId,
  }) async {
    await _firestore.collection('games').doc(gameId).update({
      'joinedPlayerIds': FieldValue.arrayRemove([userId]),
    });
  }

  Stream<GameModel> getGameStream(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((doc) => GameModel.fromMap(doc.data()!));
  }
}
