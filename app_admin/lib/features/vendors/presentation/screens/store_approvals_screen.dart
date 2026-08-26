import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/data/repositories/admin_api_repository.dart';
import 'package:shared/models/store_model.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/empty_state_widget.dart';

final adminStoresProvider = FutureProvider.family<List<StoreModel>, String?>((ref, status) async {
  final repo = ref.read(adminApiRepositoryProvider);
  return repo.fetchStores(status: status);
});

class StoreApprovalsScreen extends ConsumerStatefulWidget {
  const StoreApprovalsScreen({super.key});

  @override
  ConsumerState<StoreApprovalsScreen> createState() => _StoreApprovalsScreenState();
}

class _StoreApprovalsScreenState extends ConsumerState<StoreApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['PENDING_APPROVAL', 'PUBLISHED', 'REJECTED', 'SUSPENDED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onApprove(StoreModel store) async {
    final repo = ref.read(adminApiRepositoryProvider);
    final success = await repo.approveStore(store.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${store.name} approved and published.')));
      ref.invalidate(adminStoresProvider);
    }
  }

  void _onActionWithReason(StoreModel store, String action, Future<bool> Function(String, String) apiCall) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Store: ${store.name}'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Reason / Remarks', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await apiCall(store.id, textController.text.trim());
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Store $action successfully.')));
                ref.invalidate(adminStoresProvider);
              }
            },
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _tabs[_tabController.index];
    final storesAsync = ref.watch(adminStoresProvider(currentStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Approvals & Governance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Published'),
            Tab(text: 'Rejected'),
            Tab(text: 'Suspended'),
          ],
        ),
      ),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stores) {
          if (stores.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.store,
              title: 'No Stores Found',
              description: 'There are no stores in this queue.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: store.logo != null ? NetworkImage(store.logo!) : null,
                        child: store.logo == null ? const Icon(Icons.store) : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${store.city} • ${store.category.name}'),
                            if (store.adminRemarks != null && store.adminRemarks!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Admin Remarks: ${store.adminRemarks}', style: const TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildActionButtons(store),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(StoreModel store) {
    final repo = ref.read(adminApiRepositoryProvider);
    return Row(
      children: [
        if (store.status == 'PENDING_APPROVAL' || store.status == 'REJECTED' || store.status == 'SUSPENDED')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _onApprove(store),
              child: const Text('Approve', style: TextStyle(color: Colors.white)),
            ),
          ),
        if (store.status == 'PENDING_APPROVAL')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _onActionWithReason(store, 'Reject', repo.rejectStore),
              child: const Text('Reject'),
            ),
          ),
        if (store.status == 'PUBLISHED')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _onActionWithReason(store, 'Suspend', repo.suspendStore),
              child: const Text('Suspend'),
            ),
          ),
      ],
    );
  }
}
