import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class AdminLegalScreen extends StatelessWidget {
  final String title;
  final bool isPrivacy;

  const AdminLegalScreen({super.key, required this.title, this.isPrivacy = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isPrivacy ? Icons.privacy_tip_rounded : Icons.gavel_rounded, color: AppColors.primaryRuby, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(title, style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildSection('1. Governance & Applicability', 'This document governs the operational responsibilities of all authorized administrators, moderators, and support officers accessing the HER AREA marketplace infrastructure.'),
                    const SizedBox(height: 20),
                    _buildSection('2. Data Encryption & Privacy Protection', 'All studio KYC documents, bridal measurements, and financial GST transactions are encrypted at rest. Administrators are strictly forbidden from exporting personally identifiable information (PII) to non-corporate hardware.'),
                    const SizedBox(height: 20),
                    _buildSection('3. Dispute Resolution Protocol', 'When investigating vendor vs buyer dispute testimonials, administrators must rely on verified photographic proof and fitting measurement timelines recorded in the system database.'),
                    const SizedBox(height: 20),
                    _buildSection('4. Auditability & Session Logging', 'Every action executed in this command console—including vendor KYC approval, product rejection, and announcement broadcasts—is permanently recorded to immutable regulatory audit logs.'),
                    const SizedBox(height: 36),
                    Center(
                      child: Text('HER AREA Legal Governance HQ • Effective Date: July 2026', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildSection(String heading, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 14, color: AppColors.neutralCharcoal, height: 1.5)),
      ],
    );
  }
}
