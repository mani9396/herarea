import 'package:flutter/material.dart';

import 'package:shared/models/category_model.dart';
import 'package:shared/models/offer_model.dart';

class ReviewModel {
  final String id;
  final String store;
  final String customerName;
  final double rating;
  final String comment;
  final String status;
  final bool isVerifiedVisit;
  final String createdAt;
  final String? adminRemarks;

  const ReviewModel({
    required this.id,
    required this.store,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.status,
    required this.isVerifiedVisit,
    required this.createdAt,
    this.adminRemarks,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      customerName: json['customer_name'] ?? 'Customer',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] ?? '',
      status: json['status'] ?? 'PENDING',
      isVerifiedVisit: json['is_verified_visit'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      adminRemarks: json['admin_remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store': store,
      'customer_name': customerName,
      'rating': rating,
      'comment': comment,
      'status': status,
      'is_verified_visit': isVerifiedVisit,
      'created_at': createdAt,
      'admin_remarks': adminRemarks,
    };
  }
}

class StoreVisitModel {
  final String id;
  final String store;
  final String status;
  final String? verifiedAt;
  final String? expiresAt;
  final bool reviewed;
  final String createdAt;

  const StoreVisitModel({
    required this.id,
    required this.store,
    required this.status,
    this.verifiedAt,
    this.expiresAt,
    required this.reviewed,
    required this.createdAt,
  });

  factory StoreVisitModel.fromJson(Map<String, dynamic> json) {
    return StoreVisitModel(
      id: json['id']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      status: json['status'] ?? 'EXPIRED',
      verifiedAt: json['verified_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      reviewed: json['reviewed'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store': store,
      'status': status,
      'verified_at': verifiedAt,
      'expires_at': expiresAt,
      'reviewed': reviewed,
      'created_at': createdAt,
    };
  }
}

class StoreMediaModel {
  final String id;
  final String image;
  final int displayOrder;

  const StoreMediaModel({
    required this.id,
    required this.image,
    this.displayOrder = 0,
  });

  factory StoreMediaModel.fromJson(Map<String, dynamic> json) {
    return StoreMediaModel(
      id: json['id']?.toString() ?? '',
      image: json['image'] ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'display_order': displayOrder,
    };
  }
}

class StoreModel {
  final String id;
  final String name;
  final CategoryModel category;
  final CategoryModel? subcategory;
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
  final String? logo;
  final String? coverImage;
  final List<StoreMediaModel> gallery;
  final List<OfferModel> specialOffers;
  final List<String> serviceTags;
  final List<ReviewModel> reviews;
  final double latitude;
  final double longitude;
  final String description;
  final bool hasHomeMeasurement;
  final bool isListingEligible;
  final String status;
  final String? adminRemarks;

  const StoreModel({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
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
    this.logo,
    this.coverImage,
    this.gallery = const [],
    this.specialOffers = const [],
    this.serviceTags = const [],
    this.reviews = const [],
    required this.latitude,
    required this.longitude,
    required this.description,
    this.hasHomeMeasurement = false,
    this.isListingEligible = false,
    this.status = 'DRAFT',
    this.adminRemarks,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      name: json['business_name'] ?? json['name'] ?? json['store_name'] ?? '',
      category: json['category'] is Map 
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) 
          : CategoryModel(id: json['category']?.toString() ?? '', name: json['category_name'] ?? '', slug: json['category_slug'] ?? ''),
      subcategory: json['subcategory'] is Map 
          ? CategoryModel.fromJson(json['subcategory'] as Map<String, dynamic>) 
          : (json['subcategory_name'] != null 
              ? CategoryModel(id: json['subcategory']?.toString() ?? '', name: json['subcategory_name'], slug: json['subcategory_slug'] ?? '')
              : null),
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '') ?? 0,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 0.0,
      address: json['address_line_1'] ?? json['address'] ?? json['street_address'] ?? '',
      city: json['city'] ?? '',
      phoneNumber: json['contact_phone'] ?? json['phone_number'] ?? json['phone'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? json['whatsapp'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isSponsored: json['is_sponsored'] ?? false,
      isOpenNow: json['is_open_now'] ?? false,
      closingTimeText: json['closing_time_text'] ?? '',
      priceTier: json['price_tier'] ?? '',
      logo: json['logo'] ?? json['logo_url'],
      coverImage: json['cover_image'] ?? json['cover_url'],
      gallery: json['gallery'] != null
          ? (json['gallery'] as Iterable).map((e) => StoreMediaModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      specialOffers: json['offers'] != null
          ? (json['offers'] as Iterable).map((e) => OfferModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      serviceTags: json['service_tags'] != null
          ? List<String>.from(json['service_tags'] as Iterable)
          : const [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as Iterable).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      description: json['description'] ?? '',
      hasHomeMeasurement: json['has_home_measurement'] ?? false,
      isListingEligible: json['is_listing_eligible'] ?? false,
      status: json['status'] ?? 'DRAFT',
      adminRemarks: json['admin_remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toJson(),
      'subcategory': subcategory?.toJson(),
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
      'logo': logo,
      'cover_image': coverImage,
      'gallery': gallery.map((g) => g.toJson()).toList(),
      'special_offers': specialOffers.map((o) => o.toJson()).toList(),
      'service_tags': serviceTags,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'has_home_measurement': hasHomeMeasurement,
      'is_listing_eligible': isListingEligible,
      'status': status,
      'admin_remarks': adminRemarks,
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    CategoryModel? category,
    CategoryModel? subcategory,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    String? address,
    String? city,
    String? phoneNumber,
    String? whatsappNumber,
    bool? isVerified,
    bool? isSponsored,
    bool? isOpenNow,
    String? closingTimeText,
    String? priceTier,
    String? logo,
    String? coverImage,
    List<StoreMediaModel>? gallery,
    List<OfferModel>? specialOffers,
    List<String>? serviceTags,
    List<ReviewModel>? reviews,
    double? latitude,
    double? longitude,
    String? description,
    bool? hasHomeMeasurement,
    bool? isListingEligible,
    String? status,
    String? adminRemarks,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      address: address ?? this.address,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isVerified: isVerified ?? this.isVerified,
      isSponsored: isSponsored ?? this.isSponsored,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      closingTimeText: closingTimeText ?? this.closingTimeText,
      priceTier: priceTier ?? this.priceTier,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      gallery: gallery ?? this.gallery,
      specialOffers: specialOffers ?? this.specialOffers,
      serviceTags: serviceTags ?? this.serviceTags,
      reviews: reviews ?? this.reviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      hasHomeMeasurement: hasHomeMeasurement ?? this.hasHomeMeasurement,
      isListingEligible: isListingEligible ?? this.isListingEligible,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
    );
  }
}
