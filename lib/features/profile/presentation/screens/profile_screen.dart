import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No profile found',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return _ProfileForm(key: ValueKey(user.uid), user: user);
        },
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final UserModel user;

  const _ProfileForm({super.key, required this.user});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _aboutController;
  late final TextEditingController _ageController;
  late String? _selectedGender;
  late List<String> _selectedSports;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.name ?? '');
    _aboutController =
        TextEditingController(text: widget.user.about ?? '');
    _ageController = TextEditingController(
        text: widget.user.age?.toString() ?? '');
    _selectedGender = widget.user.gender;
    _selectedSports = List.from(widget.user.sports);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final updated = widget.user.copyWith(
        name: _nameController.text.trim(),
        about: _aboutController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        sports: _selectedSports,
      );
      await ref.read(authRepositoryProvider).saveUser(updated);
      ref.invalidate(currentUserModelProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    final initials = widget.user.initials;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),

          // Avatar
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Phone (non-editable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Text(
                  widget.user.phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline,
                    color: AppColors.textHint, size: 14),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name
          _SectionLabel(label: 'Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration:
                const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: 16),

          // About
          _SectionLabel(label: 'About You'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _aboutController,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Let others know about you...',
            ),
          ),
          const SizedBox(height: 16),

          // Age
          _SectionLabel(label: 'Age'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: 'Your age'),
          ),
          const SizedBox(height: 16),

          // Gender
          _SectionLabel(label: 'Gender (optional)'),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final isSelected = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _selectedGender = isSelected ? null : g),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: g != 'Other' ? 8 : 0),
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
                      g,
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

          // My Sports
          _SectionLabel(label: 'My Sports'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.sports.map((sport) {
              final isSelected = _selectedSports.contains(sport);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSports.remove(sport);
                    } else {
                      _selectedSports.add(sport);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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

          // Member Since
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Member since ',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Delete Account
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Account',
                      style:
                          TextStyle(color: AppColors.textPrimary)),
                  content: const Text(
                    'This feature is coming soon.',
                    style:
                        TextStyle(color: AppColors.textSecondary),
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
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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