import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _whatsappLeads = true;
  bool _smsAlerts = true;
  bool _reviewAlerts = true;
  bool _weeklyDigest = false;
  bool _marketingAdvisories = false;

  void _onSave() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification dispatch preferences saved!')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences 🔔'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('O2O Lead Dispatch Channels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Customize how bridal fitting inquiries and consultation reminders reach your phone.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: AppSpacing.lg),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('Instant WhatsApp Lead Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Receive immediate WhatsApp push notifications when a bride requests a fitting date.'),
                        value: _whatsappLeads,
                        onChanged: (v) => setState(() => _whatsappLeads = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('SMS Backup Notification Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Send secondary text alerts if WhatsApp message delivery is delayed.'),
                        value: _smsAlerts,
                        onChanged: (v) => setState(() => _smsAlerts = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('New Customer Review Badges', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Notify when a verified bride leaves a 5-star rating on your portfolio gallery.'),
                        value: _reviewAlerts,
                        onChanged: (v) => setState(() => _reviewAlerts = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Platform Analytics & Advisories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('Weekly Store Performance Digest', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Receive a recurring Monday overview of profile views and inquiry conversion analytics.'),
                        value: _weeklyDigest,
                        onChanged: (v) => setState(() => _weeklyDigest = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: AppColors.primaryRuby,
                        title: const Text('Bridal Trend Curation Newsletters', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Tips on seasonal Shravanam silk color palettes and embroidery trends.'),
                        value: _marketingAdvisories,
                        onChanged: (v) => setState(() => _marketingAdvisories = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Preferences 💾',
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
