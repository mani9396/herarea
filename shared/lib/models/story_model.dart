import '../constants/api_endpoints.dart';

class StoryModel {
  final String id;
  final String storeId;
  final String storeName;
  final String? storeLogo;
  final String? storeCity;
  final String? storeArea;
  final String storyType; // 'product_linked' or 'gallery_uploaded'
  final String mediaUrl;
  final String mediaType; // 'IMAGE' or 'VIDEO'
  final String? title;
  final String? caption;
  final double? price;
  final double? promotionalPrice;
  final String? productId; // Only populated for product_linked
  final Map<String, dynamic>? productSummary;
  final bool isProductAvailable;
  final DateTime publishedAt;
  final DateTime expiresAt;
  final int timeRemainingSeconds;
  final String status;
  final bool isActive;

  const StoryModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    this.storeCity,
    this.storeArea,
    required this.storyType,
    required this.mediaUrl,
    this.mediaType = 'IMAGE',
    this.title,
    this.caption,
    this.price,
    this.promotionalPrice,
    this.productId,
    this.productSummary,
    this.isProductAvailable = false,
    required this.publishedAt,
    required this.expiresAt,
    this.timeRemainingSeconds = 0,
    this.status = 'ACTIVE',
    this.isActive = true,
  });

  bool get isProductLinked => storyType == 'product_linked';
  bool get isGalleryUploaded => storyType == 'gallery_uploaded' || storyType == 'external';
  String get effectiveMediaUrl => resolveUrl(mediaUrl);

  /// Resolves relative media URLs (e.g., /media/...) to fully qualified URLs
  /// using the active backend base URL, ensuring Flutter Web renders them properly.
  static String resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final url = raw.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ApiEndpoints.defaultBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  static String? resolveOptionalUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return resolveUrl(raw);
  }

  /// Whether additional information was provided by vendor for gallery stories
  bool get hasAdditionalInfo {
    return (title != null && title!.trim().isNotEmpty) ||
        (caption != null && caption!.trim().isNotEmpty) ||
        price != null ||
        promotionalPrice != null;
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final storeMap = json['store'] as Map<String, dynamic>?;
    final rawProduct = json['product'] as Map<String, dynamic>?;
    Map<String, dynamic>? productMap;
    if (rawProduct != null) {
      productMap = Map<String, dynamic>.from(rawProduct);
      if (productMap['image_url'] != null) {
        productMap['image_url'] = resolveUrl(productMap['image_url']?.toString());
      }
    }

    return StoryModel(
      id: json['id']?.toString() ?? '',
      storeId: storeMap?['id']?.toString() ?? json['store_id']?.toString() ?? '',
      storeName: storeMap?['name']?.toString() ?? json['store_name']?.toString() ?? 'Artisan Boutique',
      storeLogo: resolveOptionalUrl(storeMap?['logo']?.toString() ?? json['store_logo']?.toString()),
      storeCity: storeMap?['city']?.toString() ?? json['store_city']?.toString(),
      storeArea: storeMap?['area']?.toString() ?? json['store_area']?.toString(),
      storyType: json['story_type']?.toString() ?? 'gallery_uploaded',
      mediaUrl: resolveUrl(json['media_url']?.toString()),
      mediaType: json['media_type']?.toString() ?? 'IMAGE',
      title: json['title']?.toString(),
      caption: json['caption']?.toString(),
      price: _parseDouble(json['price']),
      promotionalPrice: _parseDouble(json['promotional_price']),
      productId: json['product_id']?.toString(),
      productSummary: productMap,
      isProductAvailable: json['is_product_available'] == true,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now() : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now().add(const Duration(hours: 24)) : DateTime.now().add(const Duration(hours: 24)),
      timeRemainingSeconds: (json['time_remaining_seconds'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store': {
        'id': storeId,
        'name': storeName,
        'logo': storeLogo,
        'city': storeCity,
        'area': storeArea,
      },
      'story_type': storyType,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'title': title,
      'caption': caption,
      'price': price,
      'promotional_price': promotionalPrice,
      'product_id': productId,
      'product': productSummary,
      'is_product_available': isProductAvailable,
      'published_at': publishedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'time_remaining_seconds': timeRemainingSeconds,
      'status': status,
      'is_active': isActive,
    };
  }
}

/// Represents a vendor store's grouped collection of active 24-hour stories
class StoreStoryGroup {
  final String storeId;
  final String storeName;
  final String? storeLogo;
  final List<StoryModel> stories;

  const StoreStoryGroup({
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    required this.stories,
  });

  String get effectiveAvatarUrl {
    if (storeLogo != null && storeLogo!.isNotEmpty) {
      return StoryModel.resolveUrl(storeLogo);
    }
    return stories.isNotEmpty ? stories.first.effectiveMediaUrl : '';
  }
}

extension StoryGroupingExtension on List<StoryModel> {
  /// Groups stories by store so that multiple stories from a single vendor
  /// appear as a single tray circle that plays all of that store's stories in sequence.
  List<StoreStoryGroup> groupByStore() {
    final Map<String, List<StoryModel>> map = {};
    for (final story in this) {
      final key = story.storeId.isNotEmpty
          ? story.storeId
          : (story.storeName.isNotEmpty ? story.storeName : story.id);
      map.putIfAbsent(key, () => []).add(story);
    }
    return map.entries.map((entry) {
      final groupStories = entry.value;
      final first = groupStories.first;
      return StoreStoryGroup(
        storeId: entry.key,
        storeName: first.storeName.isNotEmpty ? first.storeName : (first.title ?? 'Story'),
        storeLogo: first.storeLogo,
        stories: groupStories,
      );
    }).toList();
  }
}
