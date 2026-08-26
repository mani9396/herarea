import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:shared/shared.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(vendorStoreProvider);
    final enquiries = ref.watch(vendorEnquiriesProvider);
    final stats = ref.watch(vendorStatsProvider).valueOrNull ?? const VendorStatsModel.empty();
    final unreadCount = ref.watch(vendorNotificationsProvider).where((n) => n.isUnread).length;
    final textTheme = Theme.of(context).textTheme;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome to HER AREA', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_rounded, size: 80, color: AppColors.primaryRuby),
                const SizedBox(height: AppSpacing.lg),
                Text('Your store isn\'t set up yet.', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                Text('Create your business profile to start receiving enquiries.', style: textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'Create Your Store',
                  onPressed: () => context.push(VendorRoutePaths.businessRegistration),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${store.name} 🌟', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.push(VendorRoutePaths.notifications),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildContent(context, ref, store, enquiries, stats, textTheme, false),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildContent(context, ref, store, enquiries, stats, textTheme, true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, StoreModel store, List<dynamic> enquiries, VendorStatsModel stats, TextTheme textTheme, bool isDesktop) {
    if (store.status != 'PUBLISHED') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoreStatusSection(context, ref, store),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(context, store),
          const SizedBox(height: AppSpacing.xl),
          Text('Key Performance Indicators (Live Backend Stats)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(stats.profileViews, 'Profile Views', 'No data yet', Icons.visibility_rounded, Colors.blue),
              _buildKpiCard(stats.trialInquiries, 'Trial Inquiries', 'No data yet', Icons.calendar_month_rounded, AppColors.primaryRuby),
              _buildKpiCard(stats.whatsappTaps, 'WhatsApp Taps', 'No data yet', Icons.chat_rounded, Colors.green),
              _buildKpiCard(stats.estLeadValue, 'Est. Lead Value', 'No data yet', Icons.currency_rupee_rounded, AppColors.accentGoldDark),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Consultation Inquiries 👑', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => context.go(VendorRoutePaths.ordersEnquiries),
                child: const Text('View All Orders ➡️'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...enquiries.take(2).map((e) => _buildEnquiryTile(context, ref, e)),
          const SizedBox(height: AppSpacing.xl),
          Text('Quick O2O Operations', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Add New Product (Phase 3)',
                  isOutlined: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton(
                  label: 'Manage Gallery (Phase 3)',
                  isOutlined: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Promotional Offers (Phase 3)',
                  isOutlined: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton(
                  label: 'System UI States & Demos 🛡️',
                  isOutlined: true,
                  onPressed: () => context.push(VendorRoutePaths.systemStatesShowcase),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildStoreStatusSection(BuildContext context, WidgetRef ref, StoreModel store) {
    if (store.status == 'PUBLISHED') return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    Color bgColor = Colors.orange.withValues(alpha: 0.1);
    Color textColor = Colors.orange;
    String statusTitle = 'Store Pending Review';
    String statusMsg = 'Your store has been submitted to HER AREA admins for approval.';
    Widget? actionButton;

    if (store.status == 'DRAFT') {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      statusTitle = 'Store Profile Incomplete';
      statusMsg = 'You must submit your store for admin approval before it goes live.';
        actionButton = CustomButton(
          label: 'Submit for Review',
          onPressed: store.isListingEligible ? () async {
            final repo = ref.read(vendorApiRepositoryProvider);
            try {
              final success = await repo.submitStoreForReview();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store submitted successfully!'), backgroundColor: Colors.green));
                ref.read(vendorStoreProvider.notifier).loadLiveStore();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red));
              }
            }
          } : null,
        );
      if (!store.isListingEligible) {
        statusMsg += ' You must purchase a listing plan first.';
      }
    } else if (store.status == 'REJECTED') {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      statusTitle = 'Store Rejected';
      statusMsg = 'Admin Remarks: ${store.adminRemarks ?? "Please update your profile."}';
      actionButton = CustomButton(
        label: 'Resubmit for Review',
        onPressed: store.isListingEligible ? () async {
          final repo = ref.read(vendorApiRepositoryProvider);
          final success = await repo.submitStoreForReview();
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store submitted successfully!')));
            ref.read(vendorStoreProvider.notifier).loadLiveStore();
          }
        } : null,
      );
    } else if (store.status == 'SUSPENDED') {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      statusTitle = 'Store Suspended';
      statusMsg = 'Admin Remarks: ${store.adminRemarks ?? "Your store has been suspended."}';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: textColor),
              const SizedBox(width: AppSpacing.sm),
              Text(statusTitle, style: textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(statusMsg, style: textTheme.bodyMedium?.copyWith(color: textColor.withValues(alpha: 0.8))),
          if (actionButton != null) ...[
            const SizedBox(height: AppSpacing.md),
            actionButton,
          ],
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accentGold, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.neutralCharcoal),
                    SizedBox(width: 4),
                    Text('Verified Gold Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutralCharcoal)),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.share_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Welcome, ${store.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Your store is currently ACTIVE & RECEIVING LEADS in ${store.city.isNotEmpty ? store.city : 'your area'}.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: () => context.push(VendorRoutePaths.businessProfile),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(25)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Preview Store Profile As Bride 👑', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String val, String title, String diff, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(diff, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEnquiryTile(BuildContext context, WidgetRef ref, dynamic e) {
    return CustomCard(
      onTap: () => context.go(VendorRoutePaths.ordersEnquiries),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(e.customerAvatar as String)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.customerName as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(e.serviceRequested as String, style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(e.dateText as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          VendorStatusChip(
            label: e.status as String,
            backgroundColor: (e.status == 'Pending' ? AppColors.accentGold : Colors.green).withValues(alpha: 0.15),
            textColor: e.status == 'Pending' ? AppColors.accentGoldDark : Colors.green,
          ),
        ],
      ),
    );
  }
}
