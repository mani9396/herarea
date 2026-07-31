import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:app_vendor/core/widgets/vendor_status_chip.dart';
import 'package:shared/shared.dart';

class EnquiryDetailsScreen extends ConsumerWidget {
  final String enquiryId;
  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiries = ref.watch(vendorEnquiriesProvider);
    final enquiry = enquiries.firstWhere((e) => e.id == enquiryId, orElse: () => enquiries.first);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Booking Details'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 36, backgroundImage: NetworkImage(enquiry.customerAvatar)),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(enquiry.customerName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 18),
                                    const SizedBox(width: 4),
                                    Text(enquiry.phoneNumber, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          VendorStatusChip(
                            label: enquiry.status,
                            backgroundColor: (enquiry.status == 'Pending' ? AppColors.accentGold : (enquiry.status == 'Accepted' ? Colors.blue : Colors.green)).withValues(alpha: 0.2),
                            textColor: enquiry.status == 'Pending' ? AppColors.accentGoldDark : (enquiry.status == 'Accepted' ? Colors.blue[800]! : Colors.green[800]!),
                          ),
                        ],
                      ),
                      const Divider(height: 36),
                      Text('Service Requested:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(enquiry.serviceRequested, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryRuby)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.accentGoldDark),
                          const SizedBox(width: 8),
                          Text('Preferred Fitting Date: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          Text(enquiry.dateText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Bridal Fitting & Measurement Notes:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.2))),
                        child: Text('"${enquiry.notes}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, height: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Quick Action Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening direct WhatsApp discussion with ${enquiry.customerName}')));
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (enquiry.status == 'Pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Reject / Busy',
                          isOutlined: true,
                          onPressed: () {
                            ref.read(vendorEnquiriesProvider.notifier).updateStatus(enquiry.id, 'Rejected');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry declined due to full boutique capacity.')));
                            context.pop();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: CustomButton(
                          label: 'Accept Booking ✔️',
                          onPressed: () {
                            ref.read(vendorEnquiriesProvider.notifier).updateStatus(enquiry.id, 'Accepted');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation accepted! Automated WhatsApp confirmation dispatched.')));
                            context.pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (enquiry.status == 'Accepted') ...[
                  CustomButton(
                    label: 'Mark Fitting Completed 🏆',
                    onPressed: () {
                      ref.read(vendorEnquiriesProvider.notifier).updateStatus(enquiry.id, 'Completed');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bridal fitting marked completed! Review request sent to bride.')));
                      context.pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
