import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/core/state/subscription_state.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';

class PlanSelectionScreen extends ConsumerStatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  ConsumerState<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends ConsumerState<PlanSelectionScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (response.orderId == null || response.paymentId == null || response.signature == null) {
        throw Exception("Missing payment details from Razorpay");
      }
      
      await ref.read(mySubscriptionProvider.notifier).verifyAndRefresh(
        response.orderId!, 
        response.paymentId!, 
        response.signature!
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Subscription Activated.'), backgroundColor: Colors.green),
        );
        context.pop(); // Go back to subscription page or dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Verification Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed. Please try again. Code: ${response.code}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _startPayment(ListingPlanModel plan) async {
    final store = ref.read(vendorStoreProvider);

    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create your store before choosing a listing plan.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      
      // Step 1: Initiate DUMMY Payment
      final orderData = await repo.createRazorpayOrder(plan.id);
      final transactionId = orderData['transaction_id'];
      
      // Step 2: Immediately verify dummy payment
      await ref.read(mySubscriptionProvider.notifier).verifyAndRefresh(
        transactionId, 
        'dummy_payment_id', 
        'dummy_signature'
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dummy Payment Successful! Subscription Activated.'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate payment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(listingPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your HER AREA Plan'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading plans: $e')),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Text('No listing plans available.', style: TextStyle(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${plan.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${plan.durationDays} days', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Text(plan.description),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _startPayment(plan),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Choose Plan', style: TextStyle(fontSize: 16)),
                              ),
                            )
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
}
