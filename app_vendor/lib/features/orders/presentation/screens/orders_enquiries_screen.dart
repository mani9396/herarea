import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:shared/shared.dart';

class OrdersEnquiriesScreen extends ConsumerStatefulWidget {
  const OrdersEnquiriesScreen({super.key});

  @override
  ConsumerState<OrdersEnquiriesScreen> createState() => _OrdersEnquiriesScreenState();
}

class _OrdersEnquiriesScreenState extends ConsumerState<OrdersEnquiriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEnquiries = ref.watch(vendorEnquiriesProvider);
    final textTheme = Theme.of(context).textTheme;

    final enquiries = _searchQuery.isEmpty
        ? allEnquiries
        : allEnquiries.where((e) => e.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) || e.serviceRequested.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bridal Consultation Bookings'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryRuby,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryRuby,
            tabs: [
              Tab(text: 'All Trials'),
              Tab(text: 'Pending (1)'),
              Tab(text: 'Accepted (1)'),
              Tab(text: 'Completed (1)'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.push(VendorRoutePaths.customerReviews),
              icon: const Icon(Icons.star_half_rounded, color: AppColors.accentGold),
              tooltip: 'Customer Reviews & Feedback',
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: CustomTextField(
                    label: 'Search consultation bookings',
                    hintText: 'Search by bride name or embroidery service...',
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    suffixWidget: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                        : const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(context, enquiries, textTheme, true),
                      _buildList(context, enquiries.where((e) => e.status == 'Pending').toList(), textTheme, true),
                      _buildList(context, enquiries.where((e) => e.status == 'Accepted').toList(), textTheme, false),
                      _buildList(context, enquiries.where((e) => e.status == 'Completed').toList(), textTheme, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> list, TextTheme textTheme, bool showActions) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.book_online_outlined,
        title: 'No bridal fitting inquiries match filter',
        description: 'Try modifying your search filter or check completed reservation histories.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: list.length,
      separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(VendorRoutePaths.buildEnquiryDetailsPath(item.id as String)),
          child: CustomCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 26, backgroundImage: NetworkImage(item.customerAvatar as String)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.customerName as String, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(item.phoneNumber as String, style: textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    VendorStatusChip(
                      label: item.status as String,
                      backgroundColor: (item.status == 'Pending' ? AppColors.accentGold : (item.status == 'Accepted' ? Colors.blue : Colors.green)).withValues(alpha: 0.15),
                      textColor: item.status == 'Pending' ? AppColors.accentGoldDark : (item.status == 'Accepted' ? Colors.blue[800]! : Colors.green[800]!),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checkroom_rounded, size: 18, color: AppColors.primaryRuby),
                          const SizedBox(width: 6),
                          Text(item.serviceRequested as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(item.dateText as String, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Notes: "${item.notes}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                    ],
                  ),
                ),
                if (item.status == 'Pending') ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Decline',
                          isOutlined: true,
                          onPressed: () => ref.read(vendorEnquiriesProvider.notifier).updateStatus(item.id as String, 'Rejected'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: CustomButton(
                          label: 'Accept & WhatsApp 💬',
                          onPressed: () => ref.read(vendorEnquiriesProvider.notifier).updateStatus(item.id as String, 'Accepted'),
                        ),
                      ),
                    ],
                  ),
                ] else if (item.status == 'Accepted') ...[
                  const SizedBox(height: AppSpacing.md),
                  CustomButton(
                    label: 'Mark Consultation Completed ✔️',
                    onPressed: () => ref.read(vendorEnquiriesProvider.notifier).updateStatus(item.id as String, 'Completed'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
