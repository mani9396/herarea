import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  bool _isLocating = false;
  bool _showMap = false;
  
  double? _lat;
  double? _lon;
  String? _area;
  String? _city;
  String? _state;
  String? _country;
  String? _postalCode;

  final MapController _mapController = MapController();
  LatLng _currentMapCenter = const LatLng(17.3850, 78.4867); // Default to Hyderabad

  Future<void> _onUseCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _showMap = false;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await _geocodeLocation(position.latitude, position.longitude);
      
      if (_lat != null && _lon != null) {
        _currentMapCenter = LatLng(_lat!, _lon!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _geocodeLocation(double lat, double lon) async {
    setState(() {
      _lat = lat;
      _lon = lon;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
        },
      );
      
      if (response.statusCode == 200) {
        final address = response.data['address'];
        if (address != null) {
          setState(() {
            _area = address['suburb'] ?? address['neighbourhood'] ?? address['sublocality'];
            _city = address['city'] ?? address['town'] ?? address['county'];
            _state = address['state'];
            _country = address['country'];
            _postalCode = address['postcode'];
          });
          return;
        }
      }
      
      throw Exception('Could not resolve location');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not determine address from coordinates. Proceeding with raw coordinates.')));
      }
    }
  }

  void _onConfirmMapPin() async {
    setState(() => _isLocating = true);
    await _geocodeLocation(_currentMapCenter.latitude, _currentMapCenter.longitude);
    setState(() {
      _isLocating = false;
      _showMap = false; // Go back to summary view to confirm
    });
  }

  void _onConfirmLocation() {
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid location first.')));
      return;
    }
    
    context.pop({
      'latitude': _lat,
      'longitude': _lon,
      'area': _area ?? 'Unknown Area',
      'city': _city ?? 'Unknown City',
      'state': _state ?? '',
      'country': _country ?? 'India',
      'postal_code': _postalCode ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Location'), centerTitle: true, elevation: 0),
      body: _showMap ? _buildMapPicker() : _buildSummaryView(),
    );
  }

  Widget _buildSummaryView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                label: '(Recommended) Use Current Location 📍',
                isLoading: _isLocating,
                onPressed: _onUseCurrentLocation,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: 'Pick Store on Map 🗺️',
                onPressed: () {
                  setState(() => _showMap = true);
                },
                isOutlined: true,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              if (_lat != null) ...[
                const Text('Store Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primaryRuby),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _area ?? 'Unknown Area', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: Text(
                          '${_city ?? ''}\n${_state ?? ''}\n${_country ?? ''}\n${_postalCode ?? ''}'.trim(),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CustomButton(
                  label: 'Confirm Location',
                  onPressed: _onConfirmLocation,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPicker() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentMapCenter,
            initialZoom: 15.0,
            onPositionChanged: (MapCamera camera, bool hasGesture) {
              _currentMapCenter = camera.center;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.herarea.vendor',
            ),
          ],
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin pointing to center
            child: Icon(Icons.location_on_rounded, size: 48, color: AppColors.primaryRuby),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: CustomButton(
            label: 'Confirm Pin Location',
            isLoading: _isLocating,
            onPressed: _onConfirmMapPin,
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () => setState(() => _showMap = false),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          ),
        )
      ],
    );
  }
}
