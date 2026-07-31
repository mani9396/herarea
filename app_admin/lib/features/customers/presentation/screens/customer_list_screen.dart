import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _search = '';
  bool _onlyBlocked = false;

  void _onToggleBlock(AdminCustomerModel c) {
    final willBlock = !c.isBlocked;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(willBlock ? 'Block User Account? 🛑' : 'Unblock User Account? 🔓'),
        content: Text(willBlock
            ? 'This will prevent "${c.fullName}" from signing in or booking fitting appointments across HER AREA.'
            : 'This will restore full marketplace purchasing privileges to "${c.fullName}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: willBlock ? Colors.red : Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(adminCustomersProvider.notifier).toggleBlockCustomer(c.id, willBlock);
              ref.read(adminActivityLogProvider.notifier).logActivity('${willBlock ? "Blocked" : "Unblocked"} customer account: "${c.fullName}"');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account status updated for ${c.fullName}')));
            },
            child: Text(willBlock ? 'Confirm Block' : 'Confirm Unblock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(adminCustomersProvider);
    final displayed = customers.where((c) {
      final matchesQuery = c.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          c.email.toLowerCase().contains(_search.toLowerCase()) ||
          c.phoneNumber.contains(_search) ||
          c.city.toLowerCase().contains(_search.toLowerCase());
      return matchesQuery && (_onlyBlocked ? c.isBlocked : true);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Customer & Buyer Directory'),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilterChip(
                label: const Text('Show Blocked Only 🛑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                selected: _onlyBlocked,
                onSelected: (val) => setState(() => _onlyBlocked = val),
                selectedColor: Colors.red.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customers by name, city, official email, or mobile number...',
                    prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.primaryRuby),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => _search = val),
                ),
              ),
              Expanded(
                child: displayed.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: _onlyBlocked ? 'No Blocked Users Found' : 'No Customers Matching Query',
                        description: 'No registered customer profiles fit this search term or restriction state.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                        itemCount: displayed.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final c = displayed[index];
                          return _buildCustomerCard(context, c);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, AdminCustomerModel c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.isBlocked ? Colors.red : Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.push(AdminRoutePaths.getCustomerDetailsUrl(c.id)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: c.isBlocked ? Colors.red.shade100 : AppColors.primaryRuby.withValues(alpha: 0.12),
                child: Text(c.fullName[0], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: c.isBlocked ? Colors.red : AppColors.primaryRuby)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.neutralCharcoal)),
                        const SizedBox(width: 10),
                        if (c.isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                            child: const Text('BLOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${c.email} • 📞 ${c.phoneNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('City: ${c.city} • Joined on ${c.joinedAt}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${c.totalOrders} Orders Placed', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryRuby)),
                  const SizedBox(height: 4),
                  Text('${c.totalInquiries} studio chat inquiries', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(c.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, color: c.isBlocked ? Colors.green : Colors.red),
                tooltip: c.isBlocked ? 'Unblock User' : 'Restrict Account',
                onPressed: () => _onToggleBlock(c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
