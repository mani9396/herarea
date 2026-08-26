import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingRegistration {
  final String fullName;
  final String email;
  final String dateOfBirth;
  final String gender;

  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
  });
}

final pendingRegistrationProvider = StateProvider<PendingRegistration?>((ref) => null);
