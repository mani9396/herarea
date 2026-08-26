import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/subscription_state.dart';

class ActiveSubscriptionScreen extends ConsumerWidget {
  const ActiveSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (sub) {
          if (sub == null || sub.status == 'EXPIRED' || sub.status == 'CANCELLED') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    sub == null ? 'No active listing plan.' : 'Your listing plan has expired.',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push(VendorRoutePaths.planSelection),
                    child: Text(sub == null ? 'Choose Plan' : 'Renew Plan'),
                  )
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Plan:', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                Text(sub.planName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                _buildRow('Status', sub.status, color: sub.status == 'ACTIVE' ? Colors.green : Colors.orange),
                const Divider(height: 32),
                _buildRow('Start Date', sub.startDate?.substring(0, 10) ?? 'N/A'),
                const Divider(height: 32),
                _buildRow('Valid Until', sub.endDate?.substring(0, 10) ?? 'N/A'),
                const Divider(height: 32),
                _buildRow('Amount Paid', '${sub.currency} ${sub.amountPaid ?? 0}'),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push(VendorRoutePaths.planSelection),
                    child: const Text('Upgrade or Renew'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
