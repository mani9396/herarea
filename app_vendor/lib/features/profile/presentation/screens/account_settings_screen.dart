import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _emailController = TextEditingController(text: 'partner@vanyasilks.co.in');
  final _phoneController = TextEditingController(text: '+91 98490 12345');
  final _managerController = TextEditingController(text: 'Raghavan Pillai (Master Cutter)');
  bool _twoFactor = true;
  bool _isLoading = false;

  void _onSave() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account profile settings saved securely!')));
      context.pop();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Account Settings 👤'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Administrative Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Used for administrative login OTP verification and KYC billing advice.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Registered Partner Mobile Number',
                  hintText: '+91 98xxx xxxxx',
                  controller: _phoneController,
                  suffixWidget: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Studio Business Email Address',
                  hintText: 'name@studio.com',
                  controller: _emailController,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Primary Operations / Master Cutter Name',
                  hintText: 'Contact person for bride consultations',
                  controller: _managerController,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: SwitchListTile(
                    activeThumbColor: AppColors.primaryRuby,
                    title: const Text('Two-Factor OTP Security (2FA)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Require secondary WhatsApp PIN verification upon logging in from a new device.'),
                    value: _twoFactor,
                    onChanged: (v) => setState(() => _twoFactor = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Update Security & Account Info 💾',
                  isLoading: _isLoading,
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
