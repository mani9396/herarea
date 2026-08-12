import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/features/offers/state/offers_provider.dart';
import 'package:shared/shared.dart';

class EditOfferScreen extends ConsumerStatefulWidget {
  final String offerId;
  const EditOfferScreen({super.key, required this.offerId});

  @override
  ConsumerState<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends ConsumerState<EditOfferScreen> {
  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final offers = ref.read(vendorOffersProvider);
    final offer = offers.firstWhere((o) => o.id == widget.offerId, orElse: () => offers.first);
    _titleController = TextEditingController(text: offer.title);
    _codeController = TextEditingController(text: offer.code);
    _descController = TextEditingController(text: offer.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    final offers = ref.read(vendorOffersProvider);
    final index = offers.indexWhere((o) => o.id == widget.offerId);
    if (index != -1) {
      final current = offers[index];
      ref.read(vendorOffersProvider.notifier).updateOffer(
        current.copyWith(
          title: _titleController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          description: _descController.text.trim(),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer updated successfully!')));
    context.pop();
  }

  void _onDelete() {
    CustomDialog.show(
      context: context,
      title: 'Delete Promotion? 🗑️',
      description: 'This promotional code will be deactivated and removed from your bridal storefront immediately.',
      confirmText: 'Delete Offer',
      onConfirm: () {
        ref.read(vendorOffersProvider.notifier).removeOffer(widget.offerId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer deleted from inventory.')));
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit / Manage Offer'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Offer',
            onPressed: _onDelete,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Modify Offer Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: 'Promotion Title',
                  hintText: 'Offer headline',
                  controller: _titleController,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Voucher Code',
                  hintText: 'Code string',
                  controller: _codeController,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Terms & Description',
                  hintText: 'Usage conditions',
                  controller: _descController,
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Promotion Changes 💾',
                  isLoading: _isLoading,
                  onPressed: _onUpdate,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomButton(
                  label: 'Delete Offer',
                  variant: ButtonVariant.outline,
                  isOutlined: true,
                  onPressed: _onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
