class OfferModel {
  final String id;
  final String title;
  final String? promoCode;
  final String description;
  final String offerType;
  final String? discountValue;
  final String? startDate;
  final String? endDate;
  final String status;
  final String? adminRemarks;
  final String? imageUrl;
  final String? storeId;
  final String? storeName;

  const OfferModel({
    required this.id,
    required this.title,
    this.promoCode,
    required this.description,
    required this.offerType,
    this.discountValue,
    this.startDate,
    this.endDate,
    required this.status,
    this.adminRemarks,
    this.imageUrl,
    this.storeId,
    this.storeName,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      promoCode: json['promo_code'],
      description: json['description'] ?? '',
      offerType: json['offer_type'] ?? 'PERCENTAGE',
      discountValue: json['discount_value']?.toString(),
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'] ?? 'DRAFT',
      adminRemarks: json['admin_remarks'],
      imageUrl: json['image_url'],
      storeId: json['store_id'],
      storeName: json['store_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (promoCode != null) 'promo_code': promoCode,
      'description': description,
      'offer_type': offerType,
      if (discountValue != null) 'discount_value': discountValue,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'status': status,
      if (adminRemarks != null) 'admin_remarks': adminRemarks,
    };
  }

  OfferModel copyWith({
    String? title,
    String? promoCode,
    String? description,
    String? offerType,
    String? discountValue,
    String? startDate,
    String? endDate,
    String? status,
    String? adminRemarks,
  }) {
    return OfferModel(
      id: id,
      title: title ?? this.title,
      promoCode: promoCode ?? this.promoCode,
      description: description ?? this.description,
      offerType: offerType ?? this.offerType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      imageUrl: imageUrl,
      storeId: storeId,
      storeName: storeName,
    );
  }
}
