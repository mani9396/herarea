import 'package:flutter/material.dart';

enum BusinessCategory {
  sarees('Saree Stores', 'Elegant silk, handloom & designer sarees', Icons.checkroom_rounded, 'sarees'),
  boutiques('Boutiques', 'Curated designer wear & customized draping', Icons.dry_cleaning_rounded, 'boutiques'),
  jewellery('Jewellery', 'Trusted antique gold, diamond & Kundan sets', Icons.diamond_rounded, 'jewellery'),
  tailoring('Tailoring', 'Master fitting, alteration & blouse works', Icons.content_cut_rounded, 'tailoring'),
  maggam('Maggam Work', 'Intricate hand Zardosi & bridal blouse embroidery', Icons.brush_rounded, 'maggam'),
  beauty('Beauty Salons', 'Hair styling, facials & organic spa wellness', Icons.face_retouching_natural_rounded, 'beauty'),
  bridal('Bridal Studios', 'Complete luxury makeup & pre-wedding trial packages', Icons.auto_awesome_rounded, 'bridal'),
  accessories('Accessories', 'Bespoke clutches, potlis & traditional footwear', Icons.shopping_bag_rounded, 'accessories');

  final String displayName;
  final String description;
  final IconData iconData;
  final String key;

  const BusinessCategory(this.displayName, this.description, this.iconData, this.key);
}

class ReviewModel {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final String date;
  final List<String> reviewImages;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.reviewImages = const [],
  });
}

class StoreModel {
  final String id;
  final String name;
  final BusinessCategory category;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String address;
  final String city;
  final String phoneNumber;
  final String whatsappNumber;
  final bool isVerified;
  final bool isSponsored;
  final bool isOpenNow;
  final String closingTimeText;
  final String priceTier; // ₹₹ to ₹₹₹₹
  final List<String> imageUrls;
  final List<String> specialOffers;
  final List<String> serviceTags;
  final List<ReviewModel> reviews;
  final double latitude;
  final double longitude;
  final String description;
  final bool hasHomeMeasurement;

  const StoreModel({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.address,
    required this.city,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.isVerified,
    this.isSponsored = false,
    required this.isOpenNow,
    required this.closingTimeText,
    required this.priceTier,
    required this.imageUrls,
    this.specialOffers = const [],
    this.serviceTags = const [],
    this.reviews = const [],
    required this.latitude,
    required this.longitude,
    required this.description,
    this.hasHomeMeasurement = false,
  });
}
