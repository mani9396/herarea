import 'package:flutter/material.dart';

class VendorProductModel {
  final String id;
  final String title;
  final String category;
  final String? categoryName;
  final String? subcategory;
  final num price;
  final bool isAvailable;
  final String imageUrl;
  final List<String> additionalImages;
  final int ordersCount;
  final String description;
  final String status;
  final String? adminRemarks;

  const VendorProductModel({
    required this.id,
    required this.title,
    required this.category,
    this.categoryName,
    this.subcategory,
    required this.price,
    required this.isAvailable,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.ordersCount,
    required this.description,
    this.status = 'DRAFT',
    this.adminRemarks,
  });

  factory VendorProductModel.fromJson(Map<String, dynamic> json) {
    return VendorProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Couture Item',
      category: json['category'] ?? json['category_name'] ?? 'Boutique Exclusive',
      categoryName: json['category_name'],
      subcategory: json['subcategory'],
      price: (json['price'] != null) ? (num.tryParse(json['price'].toString()) ?? 4500) : 4500,
      isAvailable: (json['stock_status'] != 'OUT_OF_STOCK') && (json['is_active'] ?? true),
      imageUrl: json['image_url'] ?? json['image'] ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'] as Iterable)
          : const [],
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? (json['bookings_count'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? 'Handmade artisan apparel.',
      status: json['status'] ?? 'DRAFT',
      adminRemarks: json['admin_remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'stock_status': isAvailable ? 'IN_STOCK' : 'OUT_OF_STOCK',
      'is_active': isAvailable,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'orders_count': ordersCount,
      'description': description,
      'status': status,
      'admin_remarks': adminRemarks,
    };
  }

  VendorProductModel copyWith({
    String? title,
    String? category,
    String? categoryName,
    String? subcategory,
    num? price,
    bool? isAvailable,
    String? imageUrl,
    List<String>? additionalImages,
    int? ordersCount,
    String? description,
    String? status,
    String? adminRemarks,
  }) {
    return VendorProductModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      ordersCount: ordersCount ?? this.ordersCount,
      description: description ?? this.description,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
    );
  }
}

class VendorEnquiryModel {
  final String id;
  final String customerName;
  final String customerAvatar;
  final String serviceRequested;
  final String dateText;
  final String status; // 'Pending', 'Accepted', 'Completed'
  final String phoneNumber;
  final String notes;

  const VendorEnquiryModel({
    required this.id,
    required this.customerName,
    required this.customerAvatar,
    required this.serviceRequested,
    required this.dateText,
    required this.status,
    required this.phoneNumber,
    required this.notes,
  });

  factory VendorEnquiryModel.fromJson(Map<String, dynamic> json) {
    return VendorEnquiryModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? json['user_name'] ?? 'Bespoke Client',
      customerAvatar: json['customer_avatar'] ?? json['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      serviceRequested: json['service_requested'] ?? json['service_title'] ?? json['product_title'] ?? 'Custom Couture Consultation',
      dateText: json['date_text'] ?? json['appointment_time'] ?? json['created_at']?.toString().substring(0, 10) ?? 'Scheduled',
      status: json['status']?.toString().replaceAll('_', ' ').toLowerCase() == 'confirmed' ? 'Accepted' : (json['status']?.toString() ?? 'Pending'),
      phoneNumber: json['phone_number'] ?? json['customer_phone'] ?? '+91 98888 88888',
      notes: json['notes'] ?? json['customer_message'] ?? 'Client requested measurement and styling assistance.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_avatar': customerAvatar,
      'service_requested': serviceRequested,
      'date_text': dateText,
      'status': status.toUpperCase(),
      'phone_number': phoneNumber,
      'notes': notes,
    };
  }

  VendorEnquiryModel copyWith({String? status}) {
    return VendorEnquiryModel(
      id: id,
      customerName: customerName,
      customerAvatar: customerAvatar,
      serviceRequested: serviceRequested,
      dateText: dateText,
      status: status ?? this.status,
      phoneNumber: phoneNumber,
      notes: notes,
    );
  }
}

class VendorNotificationModel {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final bool isUnread;
  final IconData icon;

  const VendorNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isUnread = true,
    required this.icon,
  });

  factory VendorNotificationModel.fromJson(Map<String, dynamic> json) {
    return VendorNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['subject'] ?? 'Notification Alert',
      description: json['description'] ?? json['message'] ?? 'You have a new studio update.',
      timestamp: json['timestamp'] ?? json['created_at']?.toString().substring(0, 10) ?? 'Just now',
      isUnread: json['is_unread'] ?? json['unread'] ?? true,
      icon: Icons.notifications_active_rounded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'is_unread': isUnread,
    };
  }
}

class VendorStatsModel {
  final String profileViews;
  final String trialInquiries;
  final String whatsappTaps;
  final String estLeadValue;
  final String totalLeadValuation;
  final String commissionSaved;
  final List<Map<String, String>> recentInvoices;

  const VendorStatsModel({
    required this.profileViews,
    required this.trialInquiries,
    required this.whatsappTaps,
    required this.estLeadValue,
    required this.totalLeadValuation,
    required this.commissionSaved,
    required this.recentInvoices,
  });

  factory VendorStatsModel.fromJson(Map<String, dynamic> json) {
    final kpi = json['kpi_metrics'] ?? json;
    return VendorStatsModel(
      profileViews: kpi['profile_views']?.toString() ?? '0',
      trialInquiries: kpi['trial_inquiries']?.toString() ?? '0',
      whatsappTaps: kpi['whatsapp_taps']?.toString() ?? '0',
      estLeadValue: kpi['est_lead_value']?.toString() ?? '₹ 0',
      totalLeadValuation: kpi['total_lead_valuation']?.toString() ?? '₹ 0',
      commissionSaved: kpi['commission_saved']?.toString() ?? '₹ 0',
      recentInvoices: (json['recent_invoices'] as List?)?.map((e) => {
        'title': e['title']?.toString() ?? 'Client Order',
        'amount': e['amount']?.toString() ?? '₹ 0',
        'method': e['method']?.toString() ?? 'Direct Bank Transfer',
      }).toList() ?? [],
    );
  }

  const VendorStatsModel.empty() : this(
    profileViews: '0',
    trialInquiries: '0',
    whatsappTaps: '0',
    estLeadValue: '₹ 0',
    totalLeadValuation: '₹ 0',
    commissionSaved: '₹ 0',
    recentInvoices: const [],
  );
}

class VendorCustomerReviewModel {
  final String id;
  final String customerName;
  final String avatarUrl;
  final double rating;
  final String dateText;
  final String comment;
  final bool verified;
  final String? vendorReply;

  const VendorCustomerReviewModel({
    required this.id,
    required this.customerName,
    required this.avatarUrl,
    required this.rating,
    required this.dateText,
    required this.comment,
    required this.verified,
    this.vendorReply,
  });

  factory VendorCustomerReviewModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at']?.toString() ?? json['date_text'] ?? json['date'] ?? '';
    final dateDisplay = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    return VendorCustomerReviewModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? json['user_name'] ?? json['name'] ?? 'Customer',
      avatarUrl: json['avatar_url'] ?? json['user_avatar_url'] ?? json['avatar'] ?? '',
      rating: (json['rating'] != null) ? (num.tryParse(json['rating'].toString())?.toDouble() ?? 5.0) : 5.0,
      dateText: dateDisplay.isEmpty ? 'Recently' : dateDisplay,
      comment: json['comment'] ?? '',
      verified: json['is_verified_visit'] ?? json['verified'] ?? false,
      vendorReply: json['vendor_reply'] ?? json['reply'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'avatar_url': avatarUrl,
      'rating': rating,
      'date_text': dateText,
      'comment': comment,
      'verified': verified,
      'vendor_reply': vendorReply,
    };
  }

  VendorCustomerReviewModel copyWith({String? vendorReply}) {
    return VendorCustomerReviewModel(
      id: id,
      customerName: customerName,
      avatarUrl: avatarUrl,
      rating: rating,
      dateText: dateText,
      comment: comment,
      verified: verified,
      vendorReply: vendorReply ?? this.vendorReply,
    );
  }
}

class VendorGalleryImageModel {
  final String id;
  final String imageUrl;
  final String? caption;
  final String? uploadedAt;

  const VendorGalleryImageModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.uploadedAt,
  });

  factory VendorGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return VendorGalleryImageModel(
      id: json['id']?.toString() ?? json['url']?.toString() ?? '',
      imageUrl: json['image_url'] ?? json['url'] ?? json['image'] ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
      caption: json['caption'],
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'caption': caption,
      'uploaded_at': uploadedAt,
    };
  }
}
