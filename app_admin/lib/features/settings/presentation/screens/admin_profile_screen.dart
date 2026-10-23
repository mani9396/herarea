import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

const String kAdminOfficialNameKey = 'admin_official_name';
const String kAdminContactPhoneKey = 'admin_contact_phone';
const String kAdminAuthorityDeptKey = 'admin_authority_dept';

final adminNameProvider = StateProvider<String>((ref) => 'Jyothsna Kiran');
final adminPhoneProvider = StateProvider<String>((ref) => '+91 95421 20130');
final adminDeptProvider = StateProvider<String>((ref) => 'Founder HQ');

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _deptController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(adminNameProvider));
    _phoneController = TextEditingController(text: ref.read(adminPhoneProvider));
    _deptController = TextEditingController(text: ref.read(adminDeptProvider));

    _nameController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadPersistedProfile();
  }

  Future<void> _loadPersistedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(kAdminOfficialNameKey);
    final savedPhone = prefs.getString(kAdminContactPhoneKey);
    final savedDept = prefs.getString(kAdminAuthorityDeptKey);

    if (savedName != null && savedName.isNotEmpty) {
      ref.read(adminNameProvider.notifier).state = savedName;
      _nameController.text = savedName;
    }
    if (savedPhone != null && savedPhone.isNotEmpty) {
      ref.read(adminPhoneProvider.notifier).state = savedPhone;
      _phoneController.text = savedPhone;
    }
    if (savedDept != null && savedDept.isNotEmpty) {
      ref.read(adminDeptProvider.notifier).state = savedDept;
      _deptController.text = savedDept;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveProfileAlterations() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final dept = _deptController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrator Official Name cannot be empty.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact Phone Number cannot be empty.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kAdminOfficialNameKey, name);
      await prefs.setString(kAdminContactPhoneKey, phone);
      await prefs.setString(kAdminAuthorityDeptKey, dept.isNotEmpty ? dept : 'Founder HQ');

      // Sync common session storage keys
      await prefs.setString('auth_user_name', name);
      await prefs.setString('auth_user_phone', phone);

      // Update Riverpod states
      ref.read(adminNameProvider.notifier).state = name;
      ref.read(adminPhoneProvider.notifier).state = phone;
      ref.read(adminDeptProvider.notifier).state = dept.isNotEmpty ? dept : 'Founder HQ';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Executive profile credentials saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving credentials: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentName = _nameController.text.trim();
    final avatarInitial = currentName.isNotEmpty ? currentName[0].toUpperCase() : 'J';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Profile & Security Credentials'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRuby,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accentGold, width: 3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              avatarInitial,
                              style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: 'Administrator Official Name',
                      hintText: 'Jyothsna Kiran',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Contact Phone Number',
                      hintText: '+91 95421 20130',
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Department / Authority Designation',
                      hintText: 'Founder HQ',
                      controller: _deptController,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          label: _isSaving ? 'Saving...' : 'Save Profile Alterations 💾',
                          isFullWidth: false,
                          onPressed: _isSaving ? () {} : _saveProfileAlterations,
                        ),
                      ],
                    ),
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

