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

  static BusinessCategory fromKey(String? key) {
    return BusinessCategory.values.firstWhere(
      (cat) => cat.key.toLowerCase() == key?.toLowerCase() || cat.displayName.toLowerCase() == key?.toLowerCase(),
      orElse: () => BusinessCategory.boutiques,
    );
  }
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userName: json['user_name'] ?? json['user']?['full_name'] ?? 'HER AREA Member',
      userAvatarUrl: json['user_avatar_url'] ?? json['user']?['avatar'] ?? 'https://i.pravatar.cc/150?u=member',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] ?? json['content'] ?? '',
      date: json['date'] ?? json['created_at']?.toString().substring(0, 10) ?? 'Recent',
      reviewImages: json['review_images'] != null
          ? List<String>.from(json['review_images'] as Iterable)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'date': date,
      'review_images': reviewImages,
    };
  }
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

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final catKey = json['category'] is Map ? json['category']['name'] : json['category_key'] ?? json['category'];
    return StoreModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['store_name'] ?? 'HER AREA Boutique',
      category: BusinessCategory.fromKey(catKey?.toString()),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 120,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 2.5,
      address: json['address'] ?? json['street_address'] ?? 'Jubilee Hills, Hyderabad',
      city: json['city'] ?? 'Hyderabad',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '+91 90000 00000',
      whatsappNumber: json['whatsapp_number'] ?? json['whatsapp'] ?? '+91 90000 00000',
      isVerified: json['is_verified'] ?? true,
      isSponsored: json['is_sponsored'] ?? false,
      isOpenNow: json['is_open_now'] ?? true,
      closingTimeText: json['closing_time_text'] ?? 'Open until 9:00 PM',
      priceTier: json['price_tier'] ?? '₹₹₹',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as Iterable)
          : const ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
      specialOffers: json['special_offers'] != null
          ? List<String>.from(json['special_offers'] as Iterable)
          : const ['10% Off on Bridal Consultations'],
      serviceTags: json['service_tags'] != null
          ? List<String>.from(json['service_tags'] as Iterable)
          : const ['Custom Styling', 'Trial Suite'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as Iterable).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 17.4326,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 78.4071,
      description: json['description'] ?? 'Exclusive women’s couture and personal styling showroom.',
      hasHomeMeasurement: json['has_home_measurement'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_key': category.key,
      'rating': rating,
      'review_count': reviewCount,
      'distance_km': distanceKm,
      'address': address,
      'city': city,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'is_verified': isVerified,
      'is_sponsored': isSponsored,
      'is_open_now': isOpenNow,
      'closing_time_text': closingTimeText,
      'price_tier': priceTier,
      'image_urls': imageUrls,
      'special_offers': specialOffers,
      'service_tags': serviceTags,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'has_home_measurement': hasHomeMeasurement,
    };
  }
}
