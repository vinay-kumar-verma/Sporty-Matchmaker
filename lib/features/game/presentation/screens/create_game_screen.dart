import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/game_repository.dart';

final createGameRepositoryProvider = Provider<CreateGameRepository>((ref) {
  return CreateGameRepository();
});

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() =>
      _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSport = AppConstants.sports.first;
  String _selectedSkillLevel = AppConstants.skillLevels.first;
  DateTime _selectedDate =
      DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 2)),
  );
  int _playersNeeded = 4;
  bool _isLoading = false;

  @override
  void dispose() {
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    if (picked != null) setState(() => _selectedTime = picked);
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _submitGame() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final userModel =
          await ref.read(authRepositoryProvider).getUser(user.uid);
      final hostName = userModel?.name ?? 'Anonymous';

      final error =
          await ref.read(createGameRepositoryProvider).createGame(
                hostId: user.uid,
                hostName: hostName,
                sport: _selectedSport,
                venue: _venueController.text.trim(),
                dateTime: _combinedDateTime,
                totalPlayersNeeded: _playersNeeded,
                skillLevel: _selectedSkillLevel,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              );

      if (error != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Time Conflict',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                error,
                style:
                    const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Choose a Different Time',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating game: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Game'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SectionLabel(label: 'Sport'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.sports.map((sport) {
                final isSelected = _selectedSport == sport;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedSport = sport),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      sport,
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
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Venue'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _venueController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText:
                    'e.g. Decathlon Sports Centre, Hinjawadi',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a venue';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('EEE, MMM d')
                        .format(_selectedDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.access_time,
                    label: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Players Needed'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total players',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _playersNeeded > AppConstants.minPlayersLimit
                            ? () => setState(() => _playersNeeded--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primary,
                      ),
                      Text(
                        '$_playersNeeded',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _playersNeeded < AppConstants.maxPlayersLimit
                          ? () => setState(() => _playersNeeded++)
                          : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Skill Level'),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.skillLevels.map((level) {
                final isSelected = _selectedSkillLevel == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedSkillLevel = level),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: level !=
                                AppConstants.skillLevels.last
                            ? 8
                            : 0,
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        level,
                        textAlign: TextAlign.center,
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
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any details for other players...',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitGame,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Create Game'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}