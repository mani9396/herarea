class PromotionPublicModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String promotionType;
  final Map<String, dynamic>? destination;
  final int priority;

  const PromotionPublicModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    required this.promotionType,
    this.destination,
    required this.priority,
  });

  factory PromotionPublicModel.fromJson(Map<String, dynamic> json) {
    return PromotionPublicModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      promotionType: json['promotion_type']?.toString() ?? 'APP',
      destination: json['destination'] as Map<String, dynamic>?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }
}
