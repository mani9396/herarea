class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;
  final List<CategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List).map((e) => CategoryModel.fromJson(e)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_url': iconUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? iconUrl,
    int? displayOrder,
    bool? isActive,
    List<CategoryModel>? subcategories,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
