import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingRegistration {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String dateOfBirth;
  final String gender;

  const PendingRegistration({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
  });
}

final pendingRegistrationProvider = StateProvider<PendingRegistration?>((ref) => null);
