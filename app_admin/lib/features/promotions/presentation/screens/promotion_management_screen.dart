import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:intl/intl.dart';

class PromotionManagementScreen extends ConsumerStatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  ConsumerState<PromotionManagementScreen> createState() => _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends ConsumerState<PromotionManagementScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(adminPromotionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Promotions & Banners', style: TextStyle(fontFamily: AppTypography.displayFont)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => context.push(AdminRoutePaths.promotionsCreate),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Promotion'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRuby,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: promotionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load promotions: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(adminPromotionsProvider.notifier).loadLivePromotions(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (promotions) {
                final filtered = promotions.where((p) {
                  if (_filter == 'All') return true;
                  return p.status.displayName == _filter;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final promo = filtered[index];
                    return _PromotionCard(promotion: promo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final statuses = ['All', 'Scheduled', 'Active', 'Suspended', 'Expired'];
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _filter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (val) {
                  setState(() => _filter = status);
                },
                selectedColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                checkmarkColor: AppColors.primaryRuby,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryRuby : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No $_filter Promotions Found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
          ),
          const SizedBox(height: 8),
          const Text('Click "Create Promotion" to add a new banner.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PromotionCard extends ConsumerWidget {
  final AdminPromotionModel promotion;

  const _PromotionCard({required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final startDate = DateTime.tryParse(promotion.startAt)?.toLocal() ?? DateTime.now();
    final endDate = DateTime.tryParse(promotion.endAt)?.toLocal() ?? DateTime.now();

    Color statusColor;
    switch (promotion.status) {
      case PromotionStatus.active:
        statusColor = Colors.green;
        break;
      case PromotionStatus.scheduled:
        statusColor = Colors.orange;
        break;
      case PromotionStatus.suspended:
        statusColor = Colors.red;
        break;
      case PromotionStatus.expired:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AdminRoutePaths.getPromotionEditUrl(promotion.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: promotion.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(promotion.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: promotion.imageUrl.isEmpty
                  ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
                  : null,
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            promotion.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Text(
                            promotion.status.displayName,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (promotion.subtitle != null && promotion.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.subtitle!,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          promotion.promotionType == 'APP' ? Icons.smartphone : Icons.language,
                          size: 14,
                          color: AppColors.primaryRuby,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            promotion.promotionType == 'APP'
                                ? 'App Dest: ${promotion.internalDestinationType ?? 'Unknown'} (${promotion.internalDestinationId})'
                                : 'Ext URL: ${promotion.externalUrl ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryRuby),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Priority: ${promotion.priority}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) async {
                final notifier = ref.read(adminPromotionsProvider.notifier);
                if (val == 'edit') {
                  context.push(AdminRoutePaths.getPromotionEditUrl(promotion.id));
                } else if (val == 'suspend') {
                  await notifier.suspendPromotion(promotion.id);
                } else if (val == 'resume') {
                  await notifier.resumePromotion(promotion.id);
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Promotion?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await notifier.deletePromotion(promotion.id);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (promotion.status == PromotionStatus.active || promotion.status == PromotionStatus.scheduled)
                  const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                if (promotion.status == PromotionStatus.suspended)
                  const PopupMenuItem(value: 'resume', child: Text('Resume')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
