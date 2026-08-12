import 'package:flutter/material.dart';

class VendorProductModel {
  final String id;
  final String title;
  final String category;
  final num price;
  final bool inStock;
  final String imageUrl;
  final int ordersCount;
  final String description;

  const VendorProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.inStock,
    required this.imageUrl,
    required this.ordersCount,
    required this.description,
  });

  factory VendorProductModel.fromJson(Map<String, dynamic> json) {
    return VendorProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Couture Item',
      category: json['category'] ?? json['category_name'] ?? 'Boutique Exclusive',
      price: (json['price'] as num?) ?? 4500,
      inStock: json['in_stock'] ?? json['is_active'] ?? true,
      imageUrl: json['image_url'] ?? json['image'] ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? (json['bookings_count'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? 'Handmade artisan apparel.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'price': price,
      'in_stock': inStock,
      'image_url': imageUrl,
      'orders_count': ordersCount,
      'description': description,
    };
  }

  VendorProductModel copyWith({
    String? title,
    String? category,
    num? price,
    bool? inStock,
    String? imageUrl,
    int? ordersCount,
    String? description,
  }) {
    return VendorProductModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
      imageUrl: imageUrl ?? this.imageUrl,
      ordersCount: ordersCount ?? this.ordersCount,
      description: description ?? this.description,
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
    return VendorCustomerReviewModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? json['user_name'] ?? json['name'] ?? 'Verified Bride',
      avatarUrl: json['avatar_url'] ?? json['user_avatar_url'] ?? json['avatar'] ?? 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      dateText: json['date_text'] ?? json['date'] ?? 'Recently',
      comment: json['comment'] ?? 'Exquisite artisan craftsmanship and prompt service.',
      verified: json['verified'] ?? true,
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
