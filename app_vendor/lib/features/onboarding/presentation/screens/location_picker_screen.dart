import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  String _selectedNeighborhood = 'Banjara Hills';
  final _pincodeController = TextEditingController(text: '500034');
  bool _isLocating = false;

  void _onUseCurrentLocation() {
    setState(() => _isLocating = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _selectedNeighborhood = 'Jubilee Hills';
          _pincodeController.text = '500033';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin Studio Location'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 48, color: AppColors.primaryRuby),
                    Positioned(
                      bottom: 12, right: 12,
                      child: FloatingActionButton.small(
                        backgroundColor: Colors.white,
                        onPressed: _onUseCurrentLocation,
                        child: _isLocating ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, color: AppColors.primaryRuby),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Hyderabad Bridal Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Select your primary commercial neighborhood for distance sorting.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedNeighborhood,
                        decoration: InputDecoration(
                          labelText: 'Commercial Zone',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Banjara Hills', 'Jubilee Hills', 'HiTech City', 'Gachibowli', 'Begumpet', 'Ameerpet', 'Balanagar']
                            .map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedNeighborhood = val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        label: 'Postal Pincode',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomButton(
                        label: 'Confirm Location Tag 📍',
                        onPressed: () {
                          context.pop('Shop 12, $_selectedNeighborhood, Hyderabad');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
