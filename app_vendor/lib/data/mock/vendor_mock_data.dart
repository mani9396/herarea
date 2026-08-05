import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

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
}

class VendorMockData {
  VendorMockData._();

  static const StoreModel vendorStoreProfile = StoreModel(
    id: 'vendor_store_01',
    name: 'Tejasi Maggam & Zardosi Studio',
    category: BusinessCategory.maggam,
    rating: 4.9,
    reviewCount: 312,
    distanceKm: 0.0,
    address: 'Shop 12, Banjara Hills Road No 12',
    city: 'Hyderabad',
    phoneNumber: '+91 9811122334',
    whatsappNumber: '+91 9811122334',
    isVerified: true,
    isOpenNow: true,
    closingTimeText: 'Closes at 8:30 PM',
    priceTier: '₹₹₹',
    description: 'Specialists in royal Maggam handwork, intricate French knot blouses, and bridal Aari embroidery. Master artisans tailor personalized motifs to match wedding jewelry.',
    imageUrls: [
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80&w=800&auto=format&fit=crop',
    ],
    specialOffers: ['Free Bridal Blouse Measurement within 5 km'],
    serviceTags: ['Express Delivery in 48 hrs', 'Home Measurement', 'Custom Bridal Motifs', 'Expert Artisans'],
    latitude: 17.4126,
    longitude: 78.4371,
  );

  static const List<VendorProductModel> initialProducts = [
    VendorProductModel(
      id: 'p1',
      title: 'Royal Kanjivaram Bridal Blouse with Zardosi',
      category: 'Maggam Blouses',
      price: 14500,
      inStock: true,
      imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=600&auto=format&fit=crop',
      ordersCount: 28,
      description: 'Handcrafted with authentic gold thread, antique beads, and emerald stones on pure raw silk.',
    ),
    VendorProductModel(
      id: 'p2',
      title: 'Bespoke Peacock Motif Aari Work Blouse',
      category: 'Aari Embroidery',
      price: 8900,
      inStock: true,
      imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=600&auto=format&fit=crop',
      ordersCount: 42,
      description: 'Intricate 3D peacock feather stitching using metallic French wires and crystals.',
    ),
    VendorProductModel(
      id: 'p3',
      title: 'Pastel Organza Saree Draping & Tassel Styling',
      category: 'Saree Styling',
      price: 4500,
      inStock: false,
      imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80&w=600&auto=format&fit=crop',
      ordersCount: 15,
      description: 'Custom edge falls, Pico finishing, and hand-woven silk pearl tassel attachments.',
    ),
  ];

  static const List<VendorEnquiryModel> initialEnquiries = [
    VendorEnquiryModel(
      id: 'eq1',
      customerName: 'Ananya Rao',
      customerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
      serviceRequested: 'Home Bridal Measurement Consultation',
      dateText: 'Tomorrow at 4:00 PM',
      status: 'Pending',
      phoneNumber: '+91 9988771122',
      notes: 'Need trial for wedding reception Kanjivaram blouses for bride and mother.',
    ),
    VendorEnquiryModel(
      id: 'eq2',
      customerName: 'Dr. Keerthi Reddy',
      customerAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop',
      serviceRequested: 'Express Maggam Alteration',
      dateText: 'Today at 6:30 PM',
      status: 'Accepted',
      phoneNumber: '+91 9876500111',
      notes: 'Urgent tightening required before Friday ceremony.',
    ),
    VendorEnquiryModel(
      id: 'eq3',
      customerName: 'Srinidhi Shetty',
      customerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=200&auto=format&fit=crop',
      serviceRequested: 'Custom Zardosi Design Consultation',
      dateText: 'July 25, 2026',
      status: 'Completed',
      phoneNumber: '+91 9112233445',
      notes: 'Delivered bespoke engagement outfit.',
    ),
  ];

  static const List<VendorNotificationModel> initialNotifications = [
    VendorNotificationModel(
      id: 'n1',
      title: 'New Home Measurement Booking!',
      description: 'Ananya Rao requested an in-person bridal consultation for tomorrow at 4:00 PM.',
      timestamp: '15 mins ago',
      icon: Icons.calendar_month_rounded,
    ),
    VendorNotificationModel(
      id: 'n2',
      title: '5-Star Verified Customer Review ⭐',
      description: 'Dr. Keerthi Reddy left a glowing review: "Their precision with beads is unmatched!"',
      timestamp: '2 hours ago',
      icon: Icons.star_rounded,
      isUnread: false,
    ),
    VendorNotificationModel(
      id: 'n3',
      title: 'Weekly Profile Milestone reached! 🚀',
      description: 'Your store appeared in 1,420 search results across Hyderabad this week (+18%).',
      timestamp: '1 day ago',
      icon: Icons.trending_up_rounded,
      isUnread: false,
    ),
  ];
}
