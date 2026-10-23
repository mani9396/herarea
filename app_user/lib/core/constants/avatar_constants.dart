import 'package:flutter/material.dart';

class UserAvatarOption {
  final String id;
  final String name;
  final String assetPath;
  final String genderCategory; // 'male', 'female', 'neutral'

  const UserAvatarOption({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.genderCategory,
  });
}

class UserAvatars {
  static const String men1 = 'assets/images/avatars/avatar_men_1.png';
  static const String men2 = 'assets/images/avatars/avatar_men_2.png';
  static const String women1 = 'assets/images/avatars/avatar_women_1.png';
  static const String women2 = 'assets/images/avatars/avatar_women_2.png';
  static const String neutral = 'assets/images/avatars/avatar_default.png';

  static const List<UserAvatarOption> all = [
    UserAvatarOption(
      id: 'men_1',
      name: 'Gentleman 1',
      assetPath: men1,
      genderCategory: 'male',
    ),
    UserAvatarOption(
      id: 'men_2',
      name: 'Gentleman 2',
      assetPath: men2,
      genderCategory: 'male',
    ),
    UserAvatarOption(
      id: 'women_1',
      name: 'Lady 1',
      assetPath: women1,
      genderCategory: 'female',
    ),
    UserAvatarOption(
      id: 'women_2',
      name: 'Lady 2',
      assetPath: women2,
      genderCategory: 'female',
    ),
    UserAvatarOption(
      id: 'default',
      name: 'Classic Profile',
      assetPath: neutral,
      genderCategory: 'neutral',
    ),
  ];

  static String getDefaultAvatarForGender(String? gender) {
    if (gender == null) return neutral;
    final g = gender.toUpperCase().trim();
    if (g == 'MALE' || g == 'M') {
      return men1;
    } else if (g == 'FEMALE' || g == 'F') {
      return women1;
    }
    return neutral;
  }

  static ImageProvider getImageProvider(String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return const AssetImage(neutral);
    }
    final clean = avatarPath.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    return AssetImage(clean);
  }
}
