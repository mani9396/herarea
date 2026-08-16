import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingRegistration {
  final String fullName;
  final String email;
  final String locality;

  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.locality,
  });
}

final pendingRegistrationProvider = StateProvider<PendingRegistration?>((ref) => null);
