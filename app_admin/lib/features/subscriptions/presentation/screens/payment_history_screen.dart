import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_subscription_state.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminPaymentsProvider),
          )
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payments found.'));
          }
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                title: Text('${payment.currency} ${payment.amount} - ${payment.planName}'),
                subtitle: Text('ID: ${payment.razorpayPaymentId ?? 'N/A'}\nDate: ${payment.createdAt.substring(0, 10)}'),
                isThreeLine: true,
                trailing: Text(
                  payment.status,
                  style: TextStyle(
                    color: payment.status == 'SUCCESS' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
