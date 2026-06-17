import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/game_repository.dart';
import '../controllers/home_controller.dart';
import '../widgets/game_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(gameRepositoryProvider).seedSampleGames());
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = ref.watch(filteredGamesProvider);
    final selectedSport =
        ref.watch(selectedSportFilterProvider);

    final isAllFilter = selectedSport == null;
    final isEmpty = filteredGames.value?.isEmpty ?? false;
    final showExtended = !isAllFilter || isEmpty;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () => ref
              .read(selectedSportFilterProvider.notifier)
              .state = null,
          child: const Text(
            'Sporty 🏸',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chats'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Games near you',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedSport == null,
                  onTap: () => ref
                      .read(
                          selectedSportFilterProvider.notifier)
                      .state = null,
                ),
                ...AppConstants.sports
                    .map((sport) => _FilterChip(
                          label: sport,
                          isSelected: selectedSport == sport,
                          onTap: () => ref
                              .read(selectedSportFilterProvider
                                  .notifier)
                              .state = sport,
                        )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredGames.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Something went wrong\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.error),
                ),
              ),
              data: (games) {
                if (games.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          _emojiForSport(selectedSport),
                          style: const TextStyle(
                              fontSize: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedSport == null
                              ? 'No games found nearby'
                              : 'No $selectedSport games found',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to create one!',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 100),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    return GameCard(
                      game: games[index],
                      onTap: () => context
                          .push('/game/${games[index].id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showExtended
            ? FloatingActionButton.extended(
                key: const ValueKey('extended'),
                onPressed: () =>
                    context.push('/create-game'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Game',
                  style: TextStyle(
                      fontWeight: FontWeight.w600),
                ),
              )
            : FloatingActionButton(
                key: const ValueKey('collapsed'),
                onPressed: () =>
                    context.push('/create-game'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  String _emojiForSport(String? sport) {
    if (sport == null) return '🏅';
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

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: AppColors.divider)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sporty 🏸',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find players. Play sports.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            _DrawerItem(
              icon: Icons.sports_outlined,
              label: 'Your Games',
              onTap: () {
                Navigator.pop(context);
                context.push('/your-games');
              },
            ),
            _DrawerItem(
              icon: Icons.group_outlined,
              label: 'Joined Games',
              onTap: () {
                Navigator.pop(context);
                context.push('/joined-games');
              },
            ),
            _DrawerItem(
              icon: Icons.star_border,
              label: 'Starred Games',
              onTap: () {
                Navigator.pop(context);
                context.push('/starred-games');
              },
            ),
            _DrawerItem(
              icon: Icons.share_outlined,
              label: 'Invite Friends',
              onTap: () {
                Navigator.pop(context);
                _shareApp(context);
              },
            ),
            _DrawerItem(
              icon: Icons.mail_outline,
              label: 'Contact Us',
              onTap: () {
                Navigator.pop(context);
                _showContact(context);
              },
            ),
            const Spacer(),
            const Divider(color: AppColors.divider),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Log Out',
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/');
              },
            ),
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                'Sporty v1.0.0',
                style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Clipboard.setData(const ClipboardData(
        text:
            'Hey! Check out Sporty — find players for sports near you!'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Contact Us',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have feedback or need help?',
              style:
                  TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.mail_outline,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'support@sporty.app',
                  style:
                      TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style:
                    TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 2),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : AppColors.textSecondary,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}