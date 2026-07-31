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
}
