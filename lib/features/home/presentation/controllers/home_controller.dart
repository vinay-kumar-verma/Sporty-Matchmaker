import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/game_repository.dart';
import '../../domain/game_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final gamesStreamProvider = StreamProvider<List<GameModel>>((ref) {
  return ref.watch(gameRepositoryProvider).getGames();
});

final selectedSportFilterProvider = StateProvider<String?>((ref) => null);

final filteredGamesProvider = Provider<AsyncValue<List<GameModel>>>((ref) {
  final gamesAsync = ref.watch(gamesStreamProvider);
  final selectedSport = ref.watch(selectedSportFilterProvider);
  final currentUser = FirebaseAuth.instance.currentUser;

  return gamesAsync.when(
    data: (games) {
      var filtered = selectedSport == null
          ? games
          : games.where((g) => g.sport == selectedSport).toList();

      filtered.sort((a, b) {
        final aIsHost = a.hostId == currentUser?.uid ? 0 : 1;
        final bIsHost = b.hostId == currentUser?.uid ? 0 : 1;
        return aIsHost.compareTo(bIsHost);
      });

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});