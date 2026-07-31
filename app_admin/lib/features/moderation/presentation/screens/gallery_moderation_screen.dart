import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class GalleryModerationScreen extends ConsumerStatefulWidget {
  const GalleryModerationScreen({super.key});

  @override
  ConsumerState<GalleryModerationScreen> createState() => _GalleryModerationScreenState();
}

class _GalleryModerationScreenState extends ConsumerState<GalleryModerationScreen> {
  bool _showApproved = false;

  void _onApprove(AdminGalleryModel img) {
    ref.read(adminGalleryProvider.notifier).approveImage(img.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Approved studio gallery photo from "${img.vendorName}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved lookbook photo from ${img.vendorName}')));
  }

  void _onReject(AdminGalleryModel img) {
    ref.read(adminGalleryProvider.notifier).rejectImage(img.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Rejected studio gallery photo from "${img.vendorName}"');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected lookbook photo from ${img.vendorName}')));
  }

  void _onDelete(AdminGalleryModel img) {
    ref.read(adminGalleryProvider.notifier).deleteImage(img.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery asset permanently discarded.')));
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(adminGalleryProvider);
    final displayed = gallery.where((g) => _showApproved ? g.status == AdminStatus.approved : g.status == AdminStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Showcase & Lookbook Moderation'),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [!_showApproved, _showApproved],
                onPressed: (idx) => setState(() => _showApproved = idx == 1),
                constraints: const BoxConstraints(minHeight: 34, minWidth: 120),
                children: const [
                  Text('Pending Inspection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Live Approved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: displayed.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.photo_library_outlined,
                  title: _showApproved ? 'No Live Lookbook Images' : 'Gallery Queue Clear!',
                  description: _showApproved ? 'Zero approved studio showcase images exist in the catalog.' : 'All incoming studio craftsmanship photos have been inspected and moderated.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : (MediaQuery.of(context).size.width < 1000 ? 2 : 3),
                    mainAxisSpacing: AppSpacing.xl,
                    crossAxisSpacing: AppSpacing.xl,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final img = displayed[index];
                    return _buildGalleryCard(context, img);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, AdminGalleryModel img) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  img.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: AdminStatusChip(status: img.status),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)]),
                    ),
                    child: Text(img.vendorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(img.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.neutralCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Uploaded: ${img.uploadedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (img.status != AdminStatus.approved)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _onApprove(img),
                        ),
                      ),
                    if (img.status != AdminStatus.approved) const SizedBox(width: 8),
                    if (img.status != AdminStatus.rejected && img.status != AdminStatus.approved)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade700), padding: const EdgeInsets.symmetric(vertical: 10)),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          onPressed: () => _onReject(img),
                        ),
                      ),
                    if (img.status == AdminStatus.approved)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade400)),
                          icon: const Icon(Icons.delete_forever_rounded, size: 18),
                          label: const Text('Remove from Lookbook'),
                          onPressed: () => _onDelete(img),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
