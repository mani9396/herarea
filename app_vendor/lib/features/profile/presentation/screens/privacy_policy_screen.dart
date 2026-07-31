import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Privacy Policy 🔒'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Protection & O2O Privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.md),
                Text(
                  '1. Transparent Lead Communication\nWhen a bride taps your WhatsApp or Call button, we share your verified business contact directly. We do not monitor or interfere with your private chat negotiations.\n\n2. No Commission Tracking\nWe do not require you to report deal values or offline payments. Your transactions remain 100% private to your boutique.\n\n3. Portfolio Ownership\nAll saree photos, Maggam blouse videos, and catalog items you upload remain your intellectual property.',
                  style: TextStyle(height: 1.6, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
