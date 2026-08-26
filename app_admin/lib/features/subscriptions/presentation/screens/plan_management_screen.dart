import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_admin/core/state/admin_subscription_state.dart';

class PlanManagementScreen extends ConsumerStatefulWidget {
  const PlanManagementScreen({super.key});

  @override
  ConsumerState<PlanManagementScreen> createState() => _PlanManagementScreenState();
}

class _PlanManagementScreenState extends ConsumerState<PlanManagementScreen> {

  Future<void> _showPlanDialog({ListingPlanModel? plan}) async {
    final nameCtrl = TextEditingController(text: plan?.name);
    final descCtrl = TextEditingController(text: plan?.description);
    final priceCtrl = TextEditingController(text: plan?.price.toString());
    final durationCtrl = TextEditingController(text: plan?.durationDays.toString() ?? '30');
    bool isActive = plan?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(plan == null ? 'Create Plan' : 'Edit Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (days)'), keyboardType: TextInputType.number),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'price': double.tryParse(priceCtrl.text) ?? 0.0,
                  'duration_days': int.tryParse(durationCtrl.text) ?? 30,
                  'is_active': isActive,
                };
                try {
                  if (plan == null) {
                    await ref.read(adminSubscriptionRepoProvider).createPlan(data);
                  } else {
                    await ref.read(adminSubscriptionRepoProvider).updatePlan(plan.id, data);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );

    if (result == true) {
      ref.invalidate(adminPlansProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(adminPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Listing Plans'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No listing plans available.'));
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text('₹${plan.price} - ${plan.durationDays} days'),
                trailing: Text(plan.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: plan.isActive ? Colors.green : Colors.red)),
                onTap: () => _showPlanDialog(plan: plan),
              );
            },
          );
        },
      ),
    );
  }
}
