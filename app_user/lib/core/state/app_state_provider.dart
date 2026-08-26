import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

/// State representing user theme preference (True for Midnight Dark Mode, False for Luxury Light Mode)
final themeModeProvider = StateProvider<bool>((ref) => false);

/// State representing network connectivity status foundation
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// State representing active discovery radius in kilometers
final discoveryRadiusProvider = StateProvider<double>((ref) => 5.0);

/// State representing notification preference toggles
final pushNotificationsProvider = StateProvider<bool>((ref) => true);
final promotionalAlertsProvider = StateProvider<bool>((ref) => true);

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier() : super(const UserLocationState(latitude: 0.0, longitude: 0.0, cityName: 'Locating...')) {
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(cityName: 'Location Required');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(cityName: 'Location Required');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String areaName = 'Unknown Area';
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'lat': position.latitude,
            'lon': position.longitude,
            'format': 'json',
          },
        );
        if (response.statusCode == 200) {
          final address = response.data['address'];
          if (address != null) {
            final subLocality = address['suburb'] ?? address['neighbourhood'] ?? address['sublocality'] ?? '';
            final locality = address['city'] ?? address['town'] ?? address['county'] ?? '';
            if (subLocality.isNotEmpty && locality.isNotEmpty) {
              areaName = '$subLocality, $locality';
            } else if (locality.isNotEmpty) {
              areaName = locality;
            } else if (subLocality.isNotEmpty) {
              areaName = subLocality;
            }
          }
        }
      } catch (_) {}

      state = UserLocationState(latitude: position.latitude, longitude: position.longitude, cityName: areaName);
    } catch (_) {}
  }

  void setLocation(UserLocationState location) {
    state = location;
  }
}

class UserLocationState {
  final double latitude;
  final double longitude;
  final String cityName;

  const UserLocationState({
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  UserLocationState copyWith({double? latitude, double? longitude, String? cityName}) {
    return UserLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
    );
  }
}

/// State representing active member profile connected to live Django backend
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final repo = ref.watch(customerApiRepositoryProvider);
  final authRepo = ref.watch(authApiRepositoryProvider);
  return UserProfileNotifier(repo, authRepo);
});

class UserProfileState {
  final String name;
  final String phone;
  final String email;
  final String locality;
  final String bio;
  final String avatarUrl;

  const UserProfileState({
    required this.name,
    required this.phone,
    required this.email,
    required this.locality,
    required this.bio,
    required this.avatarUrl,
  });

  UserProfileState copyWith({
    String? name,
    String? phone,
    String? email,
    String? locality,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfileState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      locality: locality ?? this.locality,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final CustomerApiRepository _repository;
  final AuthApiRepository _authRepository;

  UserProfileNotifier(this._repository, this._authRepository)
      : super(const UserProfileState(
          name: '',
          phone: '',
          email: '',
          locality: '',
          bio: '',
          avatarUrl: '',
        )) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final data = await _repository.getProfile();
      if (data != null) {
        state = state.copyWith(
          name: data['full_name'] ?? data['name'] ?? data['username'] ?? state.name,
          phone: data['phone_number'] ?? data['phone'] ?? state.phone,
          email: data['email'] ?? state.email,
          locality: data['city'] ?? data['locality'] ?? state.locality,
          bio: data['bio'] ?? state.bio,
          avatarUrl: data['avatar'] ?? data['avatar_url'] ?? state.avatarUrl,
        );
      }
    } catch (_) {}
  }

  Future<bool> updateProfile(UserProfileState newProfile) async {
    state = newProfile;
    try {
      final success = await _repository.updateProfile({
        'full_name': newProfile.name,
        'email': newProfile.email,
        'phone_number': newProfile.phone,
        'city': newProfile.locality,
        'bio': newProfile.bio,
      });
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {}
  }
}

/// State managing realistic customer notifications with live API fetching
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItemModel>>((ref) {
  final repo = ref.watch(customerApiRepositoryProvider);
  return NotificationsNotifier(repo);
});

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final String timeText;
  final bool isRead;
  final IconData iconData;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timeText,
    required this.isRead,
    required this.iconData,
  });

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      title: title,
      message: message,
      timeText: timeText,
      isRead: isRead ?? this.isRead,
      iconData: iconData,
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<NotificationItemModel>> {
  final CustomerApiRepository _repository;
  bool _isLoading = false;

  NotificationsNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final data = await _repository.getNotifications();
      if (data.isNotEmpty) {
        state = data.map((map) {
          return NotificationItemModel(
            id: map['id']?.toString() ?? '',
            title: map['title'] ?? 'Platform Notification',
            message: map['message'] ?? map['content'] ?? '',
            timeText: map['created_at']?.toString().substring(0, 10) ?? 'Recent',
            isRead: map['is_read'] as bool? ?? false,
            iconData: Icons.notifications_active_rounded,
          );
        }).toList();
        _isLoading = false;
        return;
      }
    } catch (_) {}
    _isLoading = false;
  }

  Future<void> markAllAsRead() async {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    await _repository.markAllNotificationsRead();
  }

  Future<void> toggleRead(String id) async {
    state = state.map((item) => item.id == id ? item.copyWith(isRead: !item.isRead) : item).toList();
    await _repository.markNotificationRead(id);
  }

  void removeNotification(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}
