import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class ProfileApprovalsScreen extends ConsumerStatefulWidget {
  const ProfileApprovalsScreen({super.key});

  @override
  ConsumerState<ProfileApprovalsScreen> createState() => _ProfileApprovalsScreenState();
}

class _ProfileApprovalsScreenState extends ConsumerState<ProfileApprovalsScreen> {
  bool _showHistory = false;

  void _onApprove(AdminProfileUpdateModel update) {
    ref.read(adminProfileUpdatesProvider.notifier).approveUpdate(update.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Approved profile revision for "${update.storeName}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Changes approved for ${update.storeName}.')));
  }

  void _onReject(AdminProfileUpdateModel update) {
    ref.read(adminProfileUpdatesProvider.notifier).rejectUpdate(update.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Rejected profile revision for "${update.storeName}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Changes rejected for ${update.storeName}.')));
  }

  @override
  Widget build(BuildContext context) {
    final allUpdates = ref.watch(adminProfileUpdatesProvider);
    final displayedUpdates = allUpdates.where((u) {
      if (_showHistory) {
        return u.status != AdminStatus.pending;
      }
      return u.status == AdminStatus.pending;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Profile Revision Requests'),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [!_showHistory, _showHistory],
                onPressed: (idx) => setState(() => _showHistory = idx == 1),
                constraints: const BoxConstraints(minHeight: 34, minWidth: 100),
                children: const [
                  Text('Pending Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Approval History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: displayedUpdates.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.done_all_rounded,
                  title: _showHistory ? 'No Past Audit History' : 'All Revisions Processed',
                  description: _showHistory
                      ? 'No historical profile modifications exist in the audit logs.'
                      : 'There are currently zero pending business profile alteration requests.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: displayedUpdates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final item = displayedUpdates[index];
                    return _buildComparisonCard(context, item);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, AdminProfileUpdateModel item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.published_with_changes_rounded, color: AppColors.primaryRuby, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${item.storeName} (${item.vendorId})',
                      style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                    ),
                  ],
                ),
                Text(
                  'Submitted: ${item.submittedAt}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Compare Old vs. New Information Submitted:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.neutralCharcoal)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: item.oldData.keys.map((key) {
                  final oldVal = item.oldData[key] ?? 'N/A';
                  final newVal = item.newData[key] ?? 'N/A';
                  final isChanged = oldVal != newVal;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isChanged ? Colors.amber.withValues(alpha: 0.1) : Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRuby)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Previous:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text(oldVal, style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: Colors.red)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requested Replacement:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text(newVal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (item.status == AdminStatus.pending) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    label: 'Reject Changes ❌',
                    variant: ButtonVariant.outline,
                    isOutlined: true,
                    isFullWidth: false,
                    onPressed: () => _onReject(item),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Approve Alteration ✅',
                    isFullWidth: false,
                    onPressed: () => _onApprove(item),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Resolved Status: ${item.status == AdminStatus.approved ? "APPROVED" : "REJECTED"}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: item.status == AdminStatus.approved ? Colors.green : Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
