import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _ownerController = TextEditingController(text: 'Tejasi Nambiar');
  final _whatsappController = TextEditingController(text: '9811122334');
  final _emailController = TextEditingController(text: 'tejasi@vanyasilkstudio.com');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Owner Contact Info'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 44, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop')),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryRuby, child: Icon(Icons.camera_alt, color: Colors.white, size: 16))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomTextField(label: 'Owner Full Name', controller: _ownerController, prefixIcon: Icons.person_rounded),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'WhatsApp Business Lead Number', controller: _whatsappController, keyboardType: TextInputType.phone, prefixIcon: Icons.chat_rounded),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'Business Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_rounded),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Update Contact Credentials 💾',
                  isLoading: _isLoading,
                  onPressed: () {
                    final router = GoRouter.of(context);
                    setState(() => _isLoading = true);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      router.pop();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
