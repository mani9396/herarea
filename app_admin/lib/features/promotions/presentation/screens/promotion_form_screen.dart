import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/data/repositories/admin_api_repository.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/models/store_model.dart';
import 'package:shared/models/category_model.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:intl/intl.dart';

class PromotionFormScreen extends ConsumerStatefulWidget {
  final String? promotionId;

  const PromotionFormScreen({super.key, this.promotionId});

  @override
  ConsumerState<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends ConsumerState<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _internalDestIdController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  
  String _promotionType = 'APP';
  String? _internalDestinationType;
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));
  
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  List<StoreModel>? _stores;
  List<CategoryModel>? _categories;
  List<AdminOfferModel>? _offers;
  bool _isLoadingDestinations = false;

  @override
  void initState() {
    super.initState();
    if (widget.promotionId != null) {
      _loadExisting();
    }
    if (_internalDestinationType != null) {
      _fetchDestinations(_internalDestinationType!);
    }
  }

  Future<void> _fetchDestinations(String type) async {
    if (type == 'STORE' && _stores != null) return;
    if (type == 'CATEGORY' && _categories != null) return;
    if (type == 'OFFER' && _offers != null) return;

    setState(() => _isLoadingDestinations = true);
    try {
      final repo = ref.read(adminApiRepositoryProvider);
      if (type == 'STORE') {
        final stores = await repo.fetchStores(status: 'PUBLISHED');
        if (mounted) setState(() => _stores = stores);
      } else if (type == 'CATEGORY') {
        final categories = await repo.fetchCategories();
        if (mounted) setState(() => _categories = categories);
      } else if (type == 'OFFER') {
        final offers = await repo.fetchOffers();
        if (mounted) setState(() => _offers = offers);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load destinations: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingDestinations = false);
    }
  }

  void _loadExisting() {
    final promos = ref.read(adminPromotionsProvider).valueOrNull;
    if (promos == null) return;
    
    final promo = promos.firstWhere(
      (p) => p.id == widget.promotionId,
      orElse: () => promos.first, // fallback, shouldn't happen if routing is right
    );
    
    _titleController.text = promo.title;
    _subtitleController.text = promo.subtitle ?? '';
    _priorityController.text = promo.priority.toString();
    _promotionType = promo.promotionType;
    _externalUrlController.text = promo.externalUrl ?? '';
    _internalDestinationType = promo.internalDestinationType;
    _internalDestIdController.text = promo.internalDestinationId ?? '';
    _startAt = DateTime.tryParse(promo.startAt)?.toLocal() ?? DateTime.now();
    _endAt = DateTime.tryParse(promo.endAt)?.toLocal() ?? DateTime.now().add(const Duration(days: 7));
    _existingImageUrl = promo.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _selectedImage = img;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_promotionType == 'APP' && _internalDestinationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an internal destination type')));
      return;
    }
    if (widget.promotionId == null && _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image for the promotion')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminApiRepositoryProvider);
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'promotion_type': _promotionType,
        'priority': int.tryParse(_priorityController.text) ?? 0,
        'start_at': _startAt.toUtc().toIso8601String(),
        'end_at': _endAt.toUtc().toIso8601String(),
      };

      if (_promotionType == 'APP') {
        data['internal_destination_type'] = _internalDestinationType;
        data['internal_destination_id'] = _internalDestIdController.text.trim();
      } else {
        data['external_url'] = _externalUrlController.text.trim();
      }

      dynamic imageFile;
      if (_selectedImage != null) {
        imageFile = _selectedImage;
      }

      if (widget.promotionId == null) {
        await repo.createPromotion(data, imageFile: imageFile);
      } else {
        await repo.updatePromotion(widget.promotionId!, data, imageFile: imageFile);
      }

      await ref.read(adminPromotionsProvider.notifier).loadLivePromotions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion saved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.promotionId == null ? 'Create Promotion' : 'Edit Promotion', style: const TextStyle(fontFamily: AppTypography.displayFont)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Banner Image'),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 32),

              _buildSectionTitle('Destination'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('In-App Navigation'),
                      value: 'APP',
                      groupValue: _promotionType,
                      onChanged: (val) => setState(() => _promotionType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('External Link'),
                      value: 'EXTERNAL',
                      groupValue: _promotionType,
                      onChanged: (val) => setState(() => _promotionType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_promotionType == 'APP') ...[
                DropdownButtonFormField<String>(
                  value: _internalDestinationType,
                  decoration: const InputDecoration(labelText: 'Destination Type *', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'STORE', child: Text('Store Profile')),
                    DropdownMenuItem(value: 'CATEGORY', child: Text('Product Category')),
                    DropdownMenuItem(value: 'OFFER', child: Text('Special Offer')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _internalDestinationType = val;
                      _internalDestIdController.clear();
                    });
                    if (val != null) _fetchDestinations(val);
                  },
                ),
                const SizedBox(height: 16),
                if (_isLoadingDestinations)
                  const Center(child: CircularProgressIndicator())
                else if (_internalDestinationType == 'STORE' && _stores != null)
                  DropdownButtonFormField<String>(
                    value: _stores!.any((s) => s.id == _internalDestIdController.text) ? _internalDestIdController.text : null,
                    decoration: const InputDecoration(labelText: 'Select Store *', border: OutlineInputBorder()),
                    items: _stores!.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setState(() => _internalDestIdController.text = val ?? ''),
                    validator: (val) => _promotionType == 'APP' && (val == null || val.isEmpty) ? 'Required' : null,
                  )
                else if (_internalDestinationType == 'CATEGORY' && _categories != null)
                  DropdownButtonFormField<String>(
                    value: _categories!.any((c) => c.id == _internalDestIdController.text) ? _internalDestIdController.text : null,
                    decoration: const InputDecoration(labelText: 'Select Category *', border: OutlineInputBorder()),
                    items: _categories!.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _internalDestIdController.text = val ?? ''),
                    validator: (val) => _promotionType == 'APP' && (val == null || val.isEmpty) ? 'Required' : null,
                  )
                else if (_internalDestinationType == 'OFFER' && _offers != null)
                  DropdownButtonFormField<String>(
                    value: _offers!.any((o) => o.id == _internalDestIdController.text) ? _internalDestIdController.text : null,
                    decoration: const InputDecoration(labelText: 'Select Offer *', border: OutlineInputBorder()),
                    items: _offers!.map((o) => DropdownMenuItem(value: o.id, child: Text(o.title))).toList(),
                    onChanged: (val) => setState(() => _internalDestIdController.text = val ?? ''),
                    validator: (val) => _promotionType == 'APP' && (val == null || val.isEmpty) ? 'Required' : null,
                  )
                else
                  TextFormField(
                    controller: _internalDestIdController,
                    decoration: const InputDecoration(labelText: 'Destination ID (UUID) *', border: OutlineInputBorder()),
                    validator: (val) => _promotionType == 'APP' && (val == null || val.isEmpty) ? 'Required' : null,
                  ),
              ] else ...[
                TextFormField(
                  controller: _externalUrlController,
                  decoration: const InputDecoration(labelText: 'External URL *', border: OutlineInputBorder()),
                  validator: (val) {
                    if (_promotionType == 'EXTERNAL' && (val == null || val.isEmpty)) return 'Required';
                    if (_promotionType == 'EXTERNAL' && !Uri.parse(val!).isAbsolute) return 'Enter a valid URL';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),

              _buildSectionTitle('Schedule & Priority'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _startAt, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (date != null) setState(() => _startAt = DateTime(date.year, date.month, date.day, _startAt.hour, _startAt.minute));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                        child: Text(DateFormat('yyyy-MM-dd').format(_startAt)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _endAt, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (date != null) setState(() => _endAt = DateTime(date.year, date.month, date.day, _endAt.hour, _endAt.minute));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                        child: Text(DateFormat('yyyy-MM-dd').format(_endAt)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(labelText: 'Priority (0 = lowest)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRuby),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.promotionId == null ? 'Create Promotion' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
              )
            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Click to upload image', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
      ),
    );
  }
}
