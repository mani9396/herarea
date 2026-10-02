import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

final adminNameProvider = StateProvider<String>((ref) => 'Dhanisha IT Executive');
final adminPhoneProvider = StateProvider<String>((ref) => '+91 98765 43210');
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(adminNameProvider));
    _phoneController = TextEditingController(text: ref.read(adminPhoneProvider));
    _deptController = TextEditingController(text: ref.read(adminDeptProvider));
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
                            decoration: BoxDecoration(color: AppColors.primaryRuby, shape: BoxShape.circle, border: Border.all(color: AppColors.accentGold, width: 3)),
                            alignment: Alignment.center,
                            child: const Text('D', style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: 'Administrator Official Name',
                      hintText: 'Dhanisha IT Executive',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Contact Phone Number',
                      hintText: '+91 98765 43210',
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
                        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                        const SizedBox(width: 16),
                        CustomButton(
                          label: 'Save Profile Alterations 💾',
                          isFullWidth: false,
                          onPressed: () {
                            ref.read(adminNameProvider.notifier).state = _nameController.text;
                            ref.read(adminPhoneProvider.notifier).state = _phoneController.text;
                            ref.read(adminDeptProvider.notifier).state = _deptController.text;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executive credentials updated!')));
                            context.pop();
                          },
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
