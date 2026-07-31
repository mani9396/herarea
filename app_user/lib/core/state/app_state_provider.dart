import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State representing user theme preference (True for Midnight Dark Mode, False for Luxury Light Mode)
final themeModeProvider = StateProvider<bool>((ref) => false);

/// State representing network connectivity status foundation
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// State representing active discovery radius in kilometers
final discoveryRadiusProvider = StateProvider<double>((ref) => 5.0);

/// State representing notification preference toggles
final pushNotificationsProvider = StateProvider<bool>((ref) => true);
final promotionalAlertsProvider = StateProvider<bool>((ref) => true);

/// State representing active location lock coordinates (default Jubilee Hills, Hyderabad)
final userLocationProvider = StateProvider<UserLocationState>((ref) {
  return const UserLocationState(latitude: 17.4326, longitude: 78.4071, cityName: 'Jubilee Hills, Hyd');
});

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

/// State representing active member profile
final userProfileProvider = StateProvider<UserProfileState>((ref) {
  return const UserProfileState(
    name: 'Priya Nambiar',
    phone: '+91 9876543210',
    email: 'priya.nambiar@luxuryfashion.in',
    locality: 'Jubilee Hills, Hyderabad',
    bio: 'Passionate handloom silk collector & ethnic couture fashion connoisseur.',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
  );
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

/// State managing realistic customer notifications
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItemModel>>((ref) {
  return NotificationsNotifier([
    NotificationItemModel(
      id: 'notif_1',
      title: 'New Bridal Kanjivaram Collection!',
      message: 'Vanya Kanjivaram has just launched their regal 2026 temple gold weaving lineup in Jubilee Hills.',
      timeText: '15m ago',
      isRead: false,
      iconData: Icons.diamond_rounded,
    ),
    NotificationItemModel(
      id: 'notif_2',
      title: 'Private Measurement Slot Confirmed',
      message: 'Tejasi Maggam & Zardosi Studio accepted your home consultation inquiry for Saturday at 3:00 PM.',
      timeText: '2h ago',
      isRead: false,
      iconData: Icons.event_available_rounded,
    ),
    NotificationItemModel(
      id: 'notif_3',
      title: 'Exclusive HER AREA VIP Benefit',
      message: 'Show your digital profile tag at Amba Organic Spa to receive complimentary hair ritual services.',
      timeText: '1d ago',
      isRead: true,
      iconData: Icons.workspace_premium_rounded,
    ),
  ]);
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
  NotificationsNotifier(super.initialState);

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  void toggleRead(String id) {
    state = state.map((item) => item.id == id ? item.copyWith(isRead: !item.isRead) : item).toList();
  }

  void removeNotification(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}
