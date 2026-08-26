import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:app_admin/data/repositories/admin_api_repository.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Suspended', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final allVendors = ref.watch(adminVendorsProvider);

    final filteredVendors = allVendors.where((vendor) {
      final matchesQuery = vendor.storeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.ownerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.phoneNumber.contains(_searchQuery);

      if (_selectedStatusFilter == 'All') return matchesQuery;
      return matchesQuery && vendor.status.displayName == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Atelier & Vendor Governance'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVendorDialog(context, ref),
        backgroundColor: AppColors.primaryRuby,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('New Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search vendors by boutique name, master cutter, category, or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusOptions.map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedStatusFilter = status),
                              backgroundColor: Theme.of(context).cardColor,
                              selectedColor: AppColors.primaryRuby.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredVendors.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'No Matching Vendors Found',
                        description: 'No partner studios match your search query or KYC verification status filter.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                        itemCount: filteredVendors.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final vendor = filteredVendors[index];
                          return _buildVendorCard(context, vendor);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, AdminVendorModel vendor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => context.push(AdminRoutePaths.getVendorDetailsUrl(vendor.id)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.12),
                child: const Icon(Icons.storefront_rounded, color: AppColors.primaryRuby, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vendor.storeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.neutralCharcoal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AdminStatusChip(status: vendor.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${vendor.category} • Owner: ${vendor.ownerName}',
                      style: TextStyle(color: AppColors.neutralCharcoal.withValues(alpha: 0.7), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${vendor.phoneNumber} • 📍 ${vendor.address}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₹${(vendor.totalRevenue / 1000).toStringAsFixed(1)}k GMV', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryRuby)),
                  const SizedBox(height: 4),
                  Text('★ ${vendor.rating} (${vendor.totalProducts} items)', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateVendorDialog(BuildContext context, WidgetRef ref) async {
    final ownerNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final businessNameCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Provision New Partner Studio', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Full Name')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Email')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number (e.g., +91...)')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: businessNameCtrl, decoration: const InputDecoration(labelText: 'Studio / Business Name')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRuby),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (ownerNameCtrl.text.isEmpty || emailCtrl.text.isEmpty || phoneCtrl.text.isEmpty || businessNameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('All fields are required.')));
                          return;
                        }
                        setState(() => isLoading = true);
                        try {
                          final repo = ref.read(adminApiRepositoryProvider);
                          final response = await repo.createVendor(
                            ownerName: ownerNameCtrl.text,
                            officialEmail: emailCtrl.text,
                            phoneNumber: phoneCtrl.text,
                            businessName: businessNameCtrl.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _showSuccessDialog(context, response['vendor_email'], response['temporary_password']);
                            // Refresh list
                            ref.invalidate(adminVendorsProvider);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error));
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Provision Vendor', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String email, String tempPassword) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vendor Created Successfully', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The vendor has been provisioned. A secure email has been sent with their credentials.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: AppSpacing.md),
            const Text('Temporary Credentials:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            SelectableText('Email: $email', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            SelectableText('Password: $tempPassword', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.primaryRuby)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Ensure the vendor logs in immediately to change this temporary password.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRuby),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
