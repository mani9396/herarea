import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/constants/avatar_constants.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedAvatar;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    final rawPhone = profile.phone.trim();
    final cleanPhone = rawPhone.startsWith('+00')
        ? ''
        : (rawPhone.startsWith('+91') && rawPhone.length > 3
            ? rawPhone.substring(3).trim()
            : rawPhone);
    _phoneController = TextEditingController(text: cleanPhone);
    _emailController = TextEditingController(text: profile.email);
    _selectedAvatar = profile.avatarUrl.trim().isNotEmpty
        ? profile.avatarUrl.trim()
        : UserAvatars.neutral;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updated = ref.read(userProfileProvider).copyWith(
        name: _nameController.text.trim(),
        avatarUrl: _selectedAvatar,
      );
      await ref.read(userProfileProvider.notifier).updateProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your profile changes have been securely saved.'),
            backgroundColor: AppColors.primaryRuby,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Prominent Selected Avatar Preview
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRuby.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          backgroundImage: UserAvatars.getImageProvider(_selectedAvatar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar Selection Label
                    const Text(
                      'Choose Your Profile Avatar',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a vector avatar that best represents you',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar Selector Grid / Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: UserAvatars.all.map((opt) {
                          final isSelected = _selectedAvatar == opt.assetPath;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAvatar = opt.assetPath;
                              });
                            },
                            borderRadius: BorderRadius.circular(32),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.accentGold : Colors.transparent,
                                  width: 2.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentGold.withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    backgroundImage: AssetImage(opt.assetPath),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Input Form Fields (Full Name is editable; Mobile Number & Email Address are read-only)
                    CustomTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        final clean = v.trim();
                        if (clean.length > 20) {
                          return 'Name cannot exceed 20 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(clean)) {
                          return 'Only alphabets and spaces allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      label: 'Mobile Number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                      suffixWidget: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF9E9E9E)),
                      ),
                      helperText: 'Registered mobile number (verified)',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      suffixWidget: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF9E9E9E)),
                      ),
                      helperText: 'Registered email address (verified)',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    CustomButton(
                      label: 'Save Profile Changes',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
