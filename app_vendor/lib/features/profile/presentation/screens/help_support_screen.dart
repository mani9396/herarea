import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Support & Hotline 💬'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.support_agent_rounded, size: 64, color: AppColors.primaryRuby),
                const SizedBox(height: AppSpacing.md),
                const Text('Dedicated Artisan Desk in Hyderabad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                const Text('Our O2O operations specialists assist bridal boutiques with listing photos, verified badges, and lead optimization.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'Chat on Partner Support WhatsApp 💬',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to +91 9000000000 O2O Support Desk...')));
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Call Helpline (10 AM - 7 PM)',
                  isOutlined: true,
                  icon: Icons.phone_in_talk_rounded,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
