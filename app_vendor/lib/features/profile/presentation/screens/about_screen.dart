import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About HER AREA O2O 🌟'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Icon(Icons.storefront_rounded, size: 72, color: AppColors.primaryRuby),
                const SizedBox(height: AppSpacing.md),
                const Text('HER AREA VENDOR PORTAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const Text('Version 1.0.0 (Phase 2 Architecture Evaluation)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'HER AREA is built on a simple premise: local luxury boutiques, master Maggam artisans, and talented bridal designers in Hyderabad deserve a zero-commission discovery platform.\n\nWe eliminate predatory aggregator cuts by providing verified direct WhatsApp and call interactions between authentic brides and talented artisans.',
                  style: TextStyle(height: 1.6, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text('Made with ❤️ in Hyderabad, India', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
