class VendorOffer {
  final String id;
  final String title;
  final String code;
  final String discountPercent;
  final String description;
  final String validUntil;
  final bool isActive;

  const VendorOffer({
    required this.id,
    required this.title,
    required this.code,
    required this.discountPercent,
    required this.description,
    required this.validUntil,
    required this.isActive,
  });

  VendorOffer copyWith({
    String? title,
    String? code,
    String? discountPercent,
    String? description,
    String? validUntil,
    bool? isActive,
  }) {
    return VendorOffer(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      description: description ?? this.description,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
    );
  }

  factory VendorOffer.fromJson(Map<String, dynamic> json) {
    return VendorOffer(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Promotional Offer',
      code: json['code'] ?? 'OFFER',
      discountPercent: json['discount_percent'] ?? json['discount'] ?? '10% OFF',
      description: json['description'] ?? 'Special boutique discount.',
      validUntil: json['valid_until'] ?? json['end_date'] ?? '31 Dec 2026',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'discount_percent': discountPercent,
      'description': description,
      'valid_until': validUntil,
      'is_active': isActive,
    };
  }
}
