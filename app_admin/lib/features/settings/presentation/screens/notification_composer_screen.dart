import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

class NotificationComposerScreen extends ConsumerStatefulWidget {
  const NotificationComposerScreen({super.key});

  @override
  ConsumerState<NotificationComposerScreen> createState() => _NotificationComposerScreenState();
}

class _NotificationComposerScreenState extends ConsumerState<NotificationComposerScreen> {
  final _titleController = TextEditingController(text: 'Festive Maggam Craft Week Kickoff! ✨');
  final _bodyController = TextEditingController(text: 'All verified partner boutiques are now offering custom complimentary sleeve tassels for bridal trousseau fittings booked this weekend!');
  String _targetGroup = 'All Registered Platform Users (Buyers & Studios)';
  final List<String> _targetOptions = [
    'All Registered Platform Users (Buyers & Studios)',
    'Verified Partner Studios & Vendors Only',
    'Customer & Bride Community Only',
    'Hyderabad Regional Users Only'
  ];

  void _onBroadcast() {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    ref.read(adminNotificationsProvider.notifier).addAnnouncement(_titleController.text.trim(), _bodyController.text.trim(), _targetGroup);
    ref.read(adminActivityLogProvider.notifier).logActivity('Broadcasted platform announcement: "${_titleController.text}" to $_targetGroup');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Push announcement successfully transmitted to target audience!')));
    _titleController.clear();
    _bodyController.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(adminNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Push Broadcasts & Announcements'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.4))),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cell_tower_rounded, color: AppColors.primaryRuby, size: 36),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Compose Broadcast Announcement 📣', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                                Text('Send priority notifications or alert memos across customer and vendor mobile devices.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Target Audience Demographics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutralCharcoal)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _targetGroup,
                          decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          items: _targetOptions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _targetGroup = val!),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Announcement Headline Title',
                          hintText: 'e.g., Weekend Bridal Fair Bonus',
                          controller: _titleController,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Message Body & Call-to-Action',
                          hintText: 'Provide complete details of the promotional campaign or governance update...',
                          controller: _bodyController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            label: 'Transmit Push Announcement 🚀',
                            isFullWidth: false,
                            onPressed: _onBroadcast,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Recent Broadcast History Log', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                const SizedBox(height: AppSpacing.md),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.12), child: const Icon(Icons.mark_chat_unread_rounded, color: AppColors.primaryRuby, size: 22)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neutralCharcoal)),
                                      Text(item.sentAt, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.body, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                    child: Text('Target: ${item.targetGroup}', style: TextStyle(color: Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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
