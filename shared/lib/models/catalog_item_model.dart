enum CatalogItemType {
  product('PRODUCT', 'Couture Product'),
  service('SERVICE', 'Consultation Service');

  final String value;
  final String label;

  const CatalogItemType(this.value, this.label);

  static CatalogItemType fromString(String? val) {
    return CatalogItemType.values.firstWhere(
      (e) => e.value.toUpperCase() == val?.toUpperCase(),
      orElse: () => CatalogItemType.product,
    );
  }
}

class CatalogItemModel {
  final String id;
  final String storeId;
  final String storeName;
  final String title;
  final String description;
  final CatalogItemType itemType;
  final double price;
  final double? discountedPrice;
  final String imageUrl;
  final List<String> additionalImages;
  final bool isAvailable;
  final int durationMinutes; // Only for SERVICE
  final List<String> availableSizes; // Only for PRODUCT
  final List<String> availableColors; // Only for PRODUCT
  final bool requiresBooking; // True for SERVICE, false or optional for PRODUCT
  
  // Phase 11 Fields
  final String status;
  final String? adminRemarks;
  final String? category;
  final String? categoryName;
  final String? subcategory;

  const CatalogItemModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.title,
    required this.description,
    required this.itemType,
    required this.price,
    this.discountedPrice,
    required this.imageUrl,
    this.additionalImages = const [],
    this.isAvailable = true,
    this.durationMinutes = 60,
    this.availableSizes = const ['S', 'M', 'L', 'XL', 'Custom Draping'],
    this.availableColors = const ['Ruby Red', 'Emerald Green', 'Royal Blue', 'Rose Gold'],
    this.requiresBooking = false,
    this.status = 'DRAFT',
    this.adminRemarks,
    this.category,
    this.categoryName,
    this.subcategory,
  });

  bool get isService => itemType == CatalogItemType.service;

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogItemModel(
      id: json['id']?.toString() ?? '',
      storeId: json['store']?.toString() ?? json['store_id']?.toString() ?? '',
      storeName: json['store_name'] ?? 'HER AREA Showroom',
      title: json['title'] ?? json['name'] ?? 'Bespoke Item',
      description: json['description'] ?? 'Handcrafted women’s luxury apparel or styling service.',
      itemType: CatalogItemType.fromString(json['item_type']),
      price: (json['price'] as num?)?.toDouble() ?? 2500.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] ?? json['image'] ?? 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600',
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'] as Iterable)
          : const [],
      isAvailable: (json['stock_status'] != 'OUT_OF_STOCK') && (json['is_available'] ?? true),
      durationMinutes: (json['duration_minutes'] ?? json['service_duration_minutes'] as num?)?.toInt() ?? 60,
      availableSizes: json['available_sizes'] != null
          ? List<String>.from(json['available_sizes'] as Iterable)
          : const ['S', 'M', 'L', 'Custom'],
      availableColors: json['available_colors'] != null
          ? List<String>.from(json['available_colors'] as Iterable)
          : const ['Red', 'Green', 'Gold'],
      requiresBooking: json['requires_booking'] ?? (json['item_type'] == 'SERVICE'),
      status: json['status'] ?? 'DRAFT',
      adminRemarks: json['admin_remarks'],
      category: json['category']?.toString(),
      categoryName: json['category_name']?.toString(),
      subcategory: json['subcategory']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'store_name': storeName,
      'title': title,
      'name': title,
      'description': description,
      'item_type': itemType.value,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'is_available': isAvailable,
      'stock_status': isAvailable ? 'IN_STOCK' : 'OUT_OF_STOCK',
      'service_duration_minutes': durationMinutes,
      'available_sizes': availableSizes,
      'available_colors': availableColors,
      'requires_booking': requiresBooking,
      'status': status,
      'admin_remarks': adminRemarks,
      'category': category,
      'subcategory': subcategory,
    };
  }
}
