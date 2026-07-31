import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';

class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> {
  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'Superadmin (Founder Level)',
      'count': '2 Assigned Executives',
      'color': AppColors.primaryRuby,
      'perms': ['Full Catalog Moderation', 'Vendor KYC Approve/Suspend', 'Financial GMV Audits', 'Staff Role Modification', 'Push Broadcast Engine', 'Database Telemetry']
    },
    {
      'role': 'Senior Bridal Fashion Moderator',
      'count': '6 Assigned Staff',
      'color': Colors.purple.shade700,
      'perms': ['Product Catalog Moderation', 'Studio Gallery Lookbooks', 'Promotional Offer Verification', 'Customer Dispute Reviews']
    },
    {
      'role': 'GST & Financial Compliance Officer',
      'count': '3 Assigned Staff',
      'color': Colors.teal.shade700,
      'perms': ['Financial GMV Audits', 'Vendor KYC Tax Document Verify', 'CSV Report Exporting']
    },
    {
      'role': 'Customer Support & Dispute Agent',
      'count': '8 Assigned Staff',
      'color': Colors.blue.shade700,
      'perms': ['Customer Dispute Reviews', 'Block/Unblock Customer Accounts', 'Order History Lookup']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role-Based Access Control (RBAC) & Team Permissions'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomButton(
              label: '+ Invite New Administrator',
              isFullWidth: false,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating invitation token dispatch modal...'))),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: _roles.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final r = _roles[index];
              final perms = r['perms'] as List<String>;
              final color = r['color'] as Color;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(Icons.shield_rounded, color: color)),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['role'], style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                                  Text(r['count'], style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color)),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Configure Privileges'),
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Configuring RBAC privileges for ${r['role']}'))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Assigned Architectural Capabilities:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: perms.map((p) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: color, size: 14),
                                const SizedBox(width: 6),
                                Text(p, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
