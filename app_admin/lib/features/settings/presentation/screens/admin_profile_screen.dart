import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();

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
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accentGold,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.neutralCharcoal),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating avatar image upload...'))),
                              ),
                            ),
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
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade300)),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hardware Key 2FA Enabled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutralCharcoal)),
                                Text('Your console logins are secured via cryptographic SMS & Authenticator challenges.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
