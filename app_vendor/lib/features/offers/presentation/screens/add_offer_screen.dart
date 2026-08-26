import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/features/offers/state/offers_provider.dart';
import 'package:shared/shared.dart';
import 'package:intl/intl.dart';

class AddOfferScreen extends ConsumerStatefulWidget {
  const AddOfferScreen({super.key});

  @override
  ConsumerState<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends ConsumerState<AddOfferScreen> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String _discount = '15% OFF';
  DateTime? _validDate;
  final bool _isLoading = false;

  void _onCreate() {
    if (_titleController.text.trim().isEmpty || _codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide Offer Title and Coupon Code!')));
      return;
    }

    ref.read(vendorOffersProvider.notifier).addOffer(
      OfferModel(
        id: '', // Backend handles ID
        title: _titleController.text.trim(),
        promoCode: _codeController.text.trim().toUpperCase(),
        discountValue: _discount,
        offerType: 'PERCENTAGE',
        description: _descController.text.trim().isEmpty ? 'Special promotional discount for bridal inquiries.' : _descController.text.trim(),
        endDate: _validDate != null ? DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(_validDate!.toUtc()) : null,
        status: 'DRAFT',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotional Offer saved as DRAFT successfully!')));
    context.pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Offer'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Offer Headline & Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: 'Promotion Title',
                  hintText: 'e.g. Dussehra Bridal Saree Discount',
                  controller: _titleController,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Voucher Code (Optional)',
                        hintText: 'e.g. BRIDE25',
                        controller: _codeController,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _discount,
                        decoration: InputDecoration(
                          labelText: 'Benefit Value',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['10% OFF', '15% OFF', '25% OFF', '500 Flat OFF', 'FREE STITCHING']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _discount = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Terms & Description',
                  hintText: 'Applicable on orders above ₹20,000...',
                  controller: _descController,
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null && mounted) {
                      setState(() => _validDate = picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Valid Until Expiration Date',
                      hintText: 'Tap to choose calendar date',
                      controller: TextEditingController(text: _validDate != null ? DateFormat('dd MMM yyyy').format(_validDate!) : ''),
                      suffixWidget: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryRuby),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Publish Promotion Now ✨',
                  isLoading: _isLoading,
                  onPressed: _onCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
