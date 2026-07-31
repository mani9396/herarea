import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class OfferModerationScreen extends ConsumerStatefulWidget {
  const OfferModerationScreen({super.key});

  @override
  ConsumerState<OfferModerationScreen> createState() => _OfferModerationScreenState();
}

class _OfferModerationScreenState extends ConsumerState<OfferModerationScreen> {
  String _filter = 'Pending';
  final List<String> _options = ['All', 'Pending', 'Approved', 'Archived'];

  void _onApprove(AdminOfferModel o) {
    ref.read(adminOffersProvider.notifier).approveOffer(o.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Approved promotional coupon [${o.code}] for ${o.vendorName}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activated promotional coupon [${o.code}].')));
  }

  void _onReject(AdminOfferModel o) {
    ref.read(adminOffersProvider.notifier).rejectOffer(o.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected coupon proposal [${o.code}].')));
  }

  void _onExpire(AdminOfferModel o) {
    ref.read(adminOffersProvider.notifier).expireOffer(o.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Force expired promotion [${o.code}].')));
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(adminOffersProvider);
    final displayed = offers.where((o) => _filter == 'All' || o.status.displayName == _filter || (_filter == 'Archived' && o.status == AdminStatus.archived)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotional Voucher & Campaign Moderation'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _options.map((opt) {
                      final isSelected = _filter == opt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(opt),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _filter = opt),
                          selectedColor: AppColors.primaryRuby.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: displayed.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.local_offer_outlined,
                        title: 'No Offers matching "$_filter"',
                        description: 'There are no seasonal discounts or bridal vouchers in this administrative state.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                        itemCount: displayed.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final o = displayed[index];
                          return _buildOfferCard(context, o);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, AdminOfferModel o) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.4))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primaryRuby, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryRuby, borderRadius: BorderRadius.circular(8)),
                        child: Text(o.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
                      ),
                      const SizedBox(width: 12),
                      AdminStatusChip(status: o.status),
                      const Spacer(),
                      Text('${o.discountPercentage}% OFF', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(o.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.neutralCharcoal)),
                  const SizedBox(height: 4),
                  Text('Vendor: ${o.vendorName} • Valid Until: ${o.validUntil}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                if (o.status == AdminStatus.pending) ...[
                  CustomButton(
                    label: 'Approve Campaign ✅',
                    isFullWidth: false,
                    onPressed: () => _onApprove(o),
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    label: 'Reject Offer ❌',
                    variant: ButtonVariant.outline,
                    isOutlined: true,
                    isFullWidth: false,
                    onPressed: () => _onReject(o),
                  ),
                ] else if (o.status == AdminStatus.approved) ...[
                  CustomButton(
                    label: 'Force Expire 🛑',
                    variant: ButtonVariant.outline,
                    isOutlined: true,
                    isFullWidth: false,
                    onPressed: () => _onExpire(o),
                  ),
                ] else
                  const Text('Resolved', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
