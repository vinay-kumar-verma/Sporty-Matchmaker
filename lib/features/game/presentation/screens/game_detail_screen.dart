import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/domain/game_model.dart';
import 'create_game_screen.dart';
import '../../data/game_repository.dart';

final gameStreamProvider =
    StreamProvider.family<GameModel, String>((ref, gameId) {
  return ref.watch(createGameRepositoryProvider).getGameStream(gameId);
});

class GameDetailScreen extends ConsumerWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  Color _skillColor(String level) {
    switch (level) {
      case 'Beginner':
        return const Color(0xFF4CAF50);
      case 'Intermediate':
        return const Color(0xFFFF9800);
      case 'Advanced':
        return const Color(0xFFF44336);
      default:
        return AppColors.textSecondary;
    }
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

  Future<void> _toggleStar(
      WidgetRef ref, String gameId, bool isStarred) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    if (isStarred) {
      await userDoc.update({
        'starredGameIds': FieldValue.arrayRemove([gameId]),
      });
    } else {
      await userDoc.update({
        'starredGameIds': FieldValue.arrayUnion([gameId]),
      });
    }
    ref.invalidate(currentUserModelProvider);
  }

  Future<void> _editTime(BuildContext context, WidgetRef ref,
      GameModel game, String userId) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(game.dateTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final newDateTime = DateTime(
        game.dateTime.year,
        game.dateTime.month,
        game.dateTime.day,
        picked.hour,
        picked.minute,
      );

      // Fix 7 — check conflict before saving
      final conflict = await ref
          .read(createGameRepositoryProvider)
          .checkConflict(
            userId: userId,
            dateTime: newDateTime,
            excludeGameId: game.id,
          );

      if (conflict != null) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Time Conflict',
                  style:
                      TextStyle(color: AppColors.textPrimary)),
              content: Text(
                'This time overlaps with ${conflict.sport} at ${conflict.venue}.',
                style: const TextStyle(
                    color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK',
                      style:
                          TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('games')
          .doc(game.id)
          .update({'dateTime': newDateTime.toIso8601String()});
    }
  }

  Future<void> _editNotes(
      BuildContext context, GameModel game) async {
    final controller =
        TextEditingController(text: game.notes ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Notes',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add notes...',
            hintStyle: TextStyle(color: AppColors.textHint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('games')
                  .doc(game.id)
                  .update({'notes': controller.text.trim()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showNoEditWarning(
      BuildContext context, String field) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cannot edit $field',
            style: const TextStyle(
                color: AppColors.textPrimary)),
        content: Text(
          '$field cannot be changed after a game is created to avoid confusion for players who have already joined.',
          style: const TextStyle(
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it',
                style:
                    TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showPlayersList(BuildContext context, GameModel game,
      String? currentUid, bool canView) {
    if (!canView) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          content: const Text(
            'Join the game to see who else is playing.',
            style: TextStyle(
                color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style:
                      TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${game.playersJoined} Player${game.playersJoined == 1 ? '' : 's'} Joined',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...game.joinedPlayerIds.map((uid) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.surfaceLight,
                        child: Text(
                          uid == game.hostId ? '👑' : '🏅',
                          style: const TextStyle(
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        uid == game.hostId
                            ? '${game.hostName} (Host)'
                            : uid == currentUid
                                ? 'You'
                                : 'Player',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameStreamProvider(gameId));
    final currentUser =
        ref.watch(authRepositoryProvider).currentUser;
    final userAsync = ref.watch(currentUserModelProvider);

    return gameAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Error: $e',
              style:
                  const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (game) {
        final isJoined = currentUser != null &&
            game.joinedPlayerIds.contains(currentUser.uid);
        final isHost = currentUser?.uid == game.hostId;
        final canJoin =
            !game.isFull && !isJoined && !isHost;
        final canViewPlayers = isJoined || isHost;

        final starredIds = userAsync.value?.starredGameIds ?? [];
        final isStarred = starredIds.contains(game.id);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(game.sport),
            actions: [
              // Star button — Fix 6
              IconButton(
                icon: Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred
                      ? const Color(0xFFFFB300)
                      : AppColors.textSecondary,
                ),
                onPressed: () =>
                    _toggleStar(ref, game.id, isStarred),
              ),
              if (isHost)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star,
                          color: AppColors.primary,
                          size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Host',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _emojiForSport(game.sport),
                        style:
                            const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        game.sport,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _skillColor(game.skillLevel)
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          game.skillLevel,
                          style: TextStyle(
                            color:
                                _skillColor(game.skillLevel),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info section
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Host',
                  value: game.hostName,
                ),
                GestureDetector(
                  onTap: isHost
                      ? () => _showNoEditWarning(
                          context, 'Venue')
                      : null,
                  child: _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Venue',
                    value: game.venue,
                    isEditable: false,
                    isHost: isHost,
                  ),
                ),
                GestureDetector(
                  onTap: isHost
                      ? () => _showNoEditWarning(
                          context, 'Date')
                      : null,
                  child: _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat('EEEE, MMMM d')
                        .format(game.dateTime),
                    isEditable: false,
                    isHost: isHost,
                  ),
                ),
                GestureDetector(
                  onTap: isHost
                      ? () => _editTime(context, ref, game,
                          currentUser!.uid)
                      : null,
                  child: _InfoRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: DateFormat('h:mm a')
                        .format(game.dateTime),
                    isEditable: isHost,
                    isHost: isHost,
                  ),
                ),
                GestureDetector(
                  onTap: isHost
                      ? () => _editNotes(context, game)
                      : null,
                  child: _InfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: game.notes != null &&
                            game.notes!.isNotEmpty
                        ? game.notes!
                        : isHost
                            ? 'Tap to add notes'
                            : 'No notes',
                    isEditable: isHost,
                    isHost: isHost,
                  ),
                ),
                const SizedBox(height: 24),

                // Players section
                const Text(
                  'Players',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: game.playersJoined /
                              game.totalPlayersNeeded,
                          backgroundColor:
                              AppColors.surfaceLight,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            game.isFull
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${game.playersJoined}/${game.totalPlayersNeeded} joined',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  game.isFull
                      ? 'Game is full'
                      : '${game.spotsLeft} spot${game.spotsLeft == 1 ? '' : 's'} left',
                  style: TextStyle(
                    color: game.isFull
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Players list button
                Opacity(
                  opacity: canViewPlayers ? 1.0 : 0.4,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPlayersList(
                        context,
                        game,
                        currentUser?.uid,
                        canViewPlayers),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize:
                          const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    icon:
                        const Icon(Icons.people_outline),
                    label: Text(
                        '${game.playersJoined}/${game.totalPlayersNeeded} Joined — View Players'),
                  ),
                ),
                const SizedBox(height: 12),

                // Chat button
                Opacity(
                  opacity: canViewPlayers ? 1.0 : 0.4,
                  child: ElevatedButton.icon(
                    onPressed: canViewPlayers
                        ? () => context.push(
                              '/chat/${game.id}?name=${Uri.encodeComponent(game.sport)}',
                            )
                        : () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor:
                                    AppColors.surface,
                                content: const Text(
                                  'Join the game to access the group chat.',
                                  style: TextStyle(
                                      color: AppColors
                                          .textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx),
                                    child: const Text('OK',
                                        style: TextStyle(
                                            color: AppColors
                                                .primary)),
                                  ),
                                ],
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize:
                          const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                        Icons.chat_bubble_outline),
                    label:
                        const Text('Group Chat'),
                  ),
                ),
                const SizedBox(height: 12),

                // Join / Leave button
                if (!isHost) ...[
                  if (isJoined)
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(
                                createGameRepositoryProvider)
                            .leaveGame(
                              gameId: game.id,
                              userId: currentUser!.uid,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                                  Text('You left the game'),
                              backgroundColor:
                                  AppColors.error,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 52),
                        side: const BorderSide(
                            color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Leave Game',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: canJoin
                          ? () async {
                              final error = await ref
                                  .read(
                                      createGameRepositoryProvider)
                                  .joinGame(
                                    gameId: game.id,
                                    userId: currentUser!.uid,
                                    gameDateTime:
                                        game.dateTime,
                                  );
                              if (context.mounted) {
                                if (error != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) =>
                                        AlertDialog(
                                      backgroundColor:
                                          AppColors.surface,
                                      content: Text(
                                        error,
                                        style: const TextStyle(
                                            color: AppColors
                                                .textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  ctx),
                                          child: const Text(
                                              'OK',
                                              style: TextStyle(
                                                  color: AppColors
                                                      .primary)),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "You've joined the game! 🎉"),
                                      backgroundColor:
                                          AppColors.success,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      child: Text(game.isFull
                          ? 'Game Full'
                          : 'Join Game'),
                    ),
                ],

                // Cancel game button for host
                if (isHost)
                  ElevatedButton(
                    onPressed: () async {
                      final confirm =
                          await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Cancel Game?',
                            style: TextStyle(
                                color:
                                    AppColors.textPrimary),
                          ),
                          content: const Text(
                            'This will permanently delete the game for all players.',
                            style: TextStyle(
                                color: AppColors
                                    .textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text(
                                  'Keep Game',
                                  style: TextStyle(
                                      color: AppColors
                                          .textSecondary)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text(
                                  'Cancel Game',
                                  style: TextStyle(
                                      color:
                                          AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('games')
                            .doc(game.id)
                            .delete();
                        if (context.mounted)
                          context.go('/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize:
                          const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditable;
  final bool isHost;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEditable = false,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (isHost && isEditable) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.edit,
                          color: AppColors.primary,
                          size: 12),
                    ],
                    if (isHost &&
                        !isEditable &&
                        label != 'Host') ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_outline,
                          color: AppColors.textHint,
                          size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}