import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/data/repositories/vendor_api_repository.dart';

class BusinessRegistrationScreen extends ConsumerStatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  ConsumerState<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends ConsumerState<BusinessRegistrationScreen> {
  final _nameController = TextEditingController(text: 'Tejasi Maggam & Zardosi Studio');
  final _descController = TextEditingController(text: 'Specialists in royal Maggam handwork, intricate French knot blouses, and bridal Aari embroidery.');
  String _selectedCategory = 'Maggam Work';
  String _priceTier = '₹₹₹';
  bool _hasHomeMeasurement = true;
  bool _isLoading = false;
  double? _lat;
  double? _lon;
  String? _area;
  String? _city;
  String? _state;
  String? _country;
  String? _postalCode;

  Future<void> _onCompleteSetup() async {
    if (_lat == null || _lon == null || _area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid store location first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(vendorApiRepositoryProvider);
      final success = await repo.saveBusinessProfile({
        'business_name': _nameController.text,
        'description': _descController.text,
        'category_name': _selectedCategory,
        'latitude': _lat,
        'longitude': _lon,
        'area': _area,
        'city': _city,
        'state': _state,
        'country': _country,
        'postal_code': _postalCode,
      });

      if (success) {
        if (mounted) context.push(VendorRoutePaths.uploadBranding);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Boutique Profile'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Step 1 of 2: Store Identity & Speciality', style: textTheme.titleMedium?.copyWith(color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.sm),
                Text('Customize how your boutique looks to brides searching around Jubilee Hills and Banjara Hills.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Boutique / Store Brand Name',
                  hintText: 'e.g. Vanya Kanjivaram Silks',
                  controller: _nameController,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final res = await context.push<String>(VendorRoutePaths.categorySelection);
                          if (res != null) setState(() => _selectedCategory = res);
                        },
                        child: AbsorbPointer(
                          child: CustomTextField(
                            label: 'Artisanal Category',
                            hintText: 'Select Specialty',
                            controller: TextEditingController(text: _selectedCategory),
                            suffixWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priceTier,
                        decoration: InputDecoration(
                          labelText: 'Price Tier',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['₹ (Budget)', '₹₹ (Moderate)', '₹₹₹ (Premium)', '₹₹₹₹ (Luxury)']
                            .map((t) => DropdownMenuItem(value: t.split(' ')[0], child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _priceTier = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'About Your Studio & Mastery (Description)',
                  hintText: 'Describe your silk sarees, bridal stitching, or jewelry craftsmanship...',
                  controller: _descController,
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    final res = await context.push<Map<String, dynamic>>(VendorRoutePaths.locationPicker);
                    if (res != null) {
                      setState(() {
                        _lat = res['latitude'] as double?;
                        _lon = res['longitude'] as double?;
                        _area = res['area'] as String?;
                        _city = res['city'] as String?;
                        _state = res['state'] as String?;
                        _country = res['country'] as String?;
                        _postalCode = res['postal_code'] as String?;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primaryRuby),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _area != null ? '📍 $_area\n$_city' : 'Tap to pick exact coordinate location',
                            style: TextStyle(
                              color: _area != null ? Colors.black87 : Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  value: _hasHomeMeasurement,
                  activeThumbColor: AppColors.primaryRuby,
                  title: const Text('Offer Home Measurement & Trials?'),
                  subtitle: const Text('Receive special badge displayed to VIP brides requesting in-person fittings at home.'),
                  onChanged: (v) => setState(() => _hasHomeMeasurement = v),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Showcase Portfolio Preview', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildAddImageTile(),
                      const SizedBox(width: AppSpacing.sm),
                      _buildPreviewThumb('https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=300&auto=format&fit=crop'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildPreviewThumb('https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=300&auto=format&fit=crop'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Launch Partner Dashboard ✨',
                  isLoading: _isLoading,
                  onPressed: _onCompleteSetup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageTile() {
    return InkWell(
      onTap: () {},
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryRuby, style: BorderStyle.solid, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryRuby.withValues(alpha: 0.05),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.primaryRuby, size: 28),
            SizedBox(height: 4),
            Text('Upload Photo', style: TextStyle(color: AppColors.primaryRuby, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewThumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(url, width: 120, height: 120, fit: BoxFit.cover),
          Positioned(
            top: 4, right: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
