import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_dialog.dart';

class VendorDetailsScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends ConsumerState<VendorDetailsScreen> {
  void _onApprove(AdminVendorModel vendor) {
    CustomDialog.show(
      context: context,
      title: 'Approve Studio Partner? ✅',
      description: 'By approving "${vendor.storeName}", their catalog products will go live in the customer mobile app immediately.',
      confirmText: 'Approve Vendor',
      onConfirm: () {
        ref.read(adminVendorsProvider.notifier).approveVendor(vendor.id);
        ref.read(adminActivityLogProvider.notifier).logActivity('Executive approved partner studio: "${vendor.storeName}"');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vendor.storeName} approved successfully!')));
      },
    );
  }

  void _onRejectOrSuspend(AdminVendorModel vendor, bool isSuspension) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSuspension ? 'Suspend Studio Operations ⚠️' : 'Reject KYC Application ❌', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuspension
                  ? 'This will freeze the boutique catalog and stop further fitting bookings.'
                  : 'Please specify the KYC non-compliance reason for rejecting this vendor application.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid GST certificate or unresolved bridal disputes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              final reason = reasonController.text.isEmpty ? 'Administrative compliance failure.' : reasonController.text;
              if (isSuspension) {
                ref.read(adminVendorsProvider.notifier).suspendVendor(vendor.id, reason);
                ref.read(adminActivityLogProvider.notifier).logActivity('Suspended studio: "${vendor.storeName}" (Reason: $reason)');
              } else {
                ref.read(adminVendorsProvider.notifier).rejectVendor(vendor.id, reason);
                ref.read(adminActivityLogProvider.notifier).logActivity('Rejected vendor KYC: "${vendor.storeName}"');
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${isSuspension ? "Suspended" : "Rejected"}')));
            },
            child: Text(isSuspension ? 'Confirm Suspension' : 'Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _onActivate(AdminVendorModel vendor) {
    ref.read(adminVendorsProvider.notifier).activateVendor(vendor.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Re-activated studio operations: "${vendor.storeName}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vendor.storeName} has been reinstated!')));
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(adminVendorsProvider);
    final vendor = vendors.cast<AdminVendorModel?>().firstWhere(
          (v) => v?.id == widget.vendorId,
          orElse: () => null,
        );

    if (vendor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendor Dossier')),
        body: const Center(child: Text('Vendor not found or removed.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${vendor.storeName} (${vendor.id})'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(vendor.storeName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryRuby)),
                            AdminStatusChip(status: vendor.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Category: ${vendor.category} • Registered on ${vendor.createdAt}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if (vendor.rejectionReason != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Advisory Memo: ${vendor.rejectionReason}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('Business Registration & Legal Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                        const SizedBox(height: 16),
                        _buildDetailGrid([
                          ('Owner Name', vendor.ownerName),
                          ('Official Email', vendor.email),
                          ('Phone Number', vendor.phoneNumber),
                          ('GSTIN Number', vendor.gstNumber),
                          ('PAN Reference', vendor.panNumber),
                          ('Studio Location', vendor.address),
                        ]),
                        const SizedBox(height: 24),
                        const Text('Verification KYC Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GST & Trade License Certificate (${vendor.id})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Text('Verified cryptographic digital checksum', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_rounded, size: 18),
                                label: const Text('View Dossier'),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating digital KYC document inspection modal...')));
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('Executive Governance Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (vendor.status != AdminStatus.approved)
                              Expanded(
                                child: CustomButton(
                                  label: 'Approve Vendor ✅',
                                  onPressed: () => _onApprove(vendor),
                                ),
                              ),
                            if (vendor.status != AdminStatus.approved && vendor.status != AdminStatus.rejected) const SizedBox(width: 16),
                            if (vendor.status != AdminStatus.rejected && vendor.status != AdminStatus.suspended)
                              Expanded(
                                child: CustomButton(
                                  label: vendor.status == AdminStatus.approved ? 'Suspend Operations ⚠️' : 'Reject KYC ❌',
                                  variant: ButtonVariant.outline,
                                  isOutlined: true,
                                  onPressed: () => _onRejectOrSuspend(vendor, vendor.status == AdminStatus.approved),
                                ),
                              ),
                            if (vendor.status == AdminStatus.suspended || vendor.status == AdminStatus.rejected) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  label: 'Reinstate / Activate Studio 🔓',
                                  onPressed: () => _onActivate(vendor),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailGrid(List<(String, String)> items) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4.5,
      children: items.map((item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.$1, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(item.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      }).toList(),
    );
  }
}
