import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class DemoLoginButtons extends StatelessWidget {
  final void Function(String email, String password) onDemoSelected;

  const DemoLoginButtons({
    super.key,
    required this.onDemoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'DEMO LOGIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _buildDemoButton(
              context,
              'Customer Demo',
              Icons.person_rounded,
              'customer.demo@herarea.com',
            ),
            _buildDemoButton(
              context,
              'Vendor Demo',
              Icons.storefront_rounded,
              'vendor.demo@herarea.com',
            ),
            _buildDemoButton(
              context,
              'Admin Demo',
              Icons.admin_panel_settings_rounded,
              'admin.demo@herarea.com',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButton(
      BuildContext context, String label, IconData icon, String email) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryRuby),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralCharcoal)),
      backgroundColor: AppColors.primaryRubyLight.withValues(alpha: 0.1),
      side: const BorderSide(color: AppColors.primaryRuby, width: 1),
      onPressed: () => onDemoSelected(email, 'Demo@12345'),
    );
  }
}
