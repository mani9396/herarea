enum AdminStatus {
  draft,
  pending,
  approved,
  rejected,
  suspended,
  archived;

  String get displayName {
    switch (this) {
      case AdminStatus.draft:
        return 'Draft';
      case AdminStatus.pending:
        return 'Pending';
      case AdminStatus.approved:
        return 'Approved';
      case AdminStatus.rejected:
        return 'Rejected';
      case AdminStatus.suspended:
        return 'Suspended';
      case AdminStatus.archived:
        return 'Archived';
    }
  }
}

class AdminVendorModel {
  final String id;
  final String storeName;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String category;
  final String address;
  final String gstNumber;
  final String panNumber;
  final String documentUrl;
  final double rating;
  final int totalProducts;
  final double totalRevenue;
  final AdminStatus status;
  final String createdAt;
  final String? rejectionReason;

  const AdminVendorModel({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.category,
    required this.address,
    required this.gstNumber,
    required this.panNumber,
    required this.documentUrl,
    required this.rating,
    required this.totalProducts,
    required this.totalRevenue,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  AdminVendorModel copyWith({
    AdminStatus? status,
    String? rejectionReason,
  }) {
    return AdminVendorModel(
      id: id,
      storeName: storeName,
      ownerName: ownerName,
      email: email,
      phoneNumber: phoneNumber,
      category: category,
      address: address,
      gstNumber: gstNumber,
      panNumber: panNumber,
      documentUrl: documentUrl,
      rating: rating,
      totalProducts: totalProducts,
      totalRevenue: totalRevenue,
      status: status ?? this.status,
      createdAt: createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class AdminProfileUpdateModel {
  final String id;
  final String vendorId;
  final String storeName;
  final Map<String, String> oldData;
  final Map<String, String> newData;
  final AdminStatus status;
  final String submittedAt;

  const AdminProfileUpdateModel({
    required this.id,
    required this.vendorId,
    required this.storeName,
    required this.oldData,
    required this.newData,
    required this.status,
    required this.submittedAt,
  });

  AdminProfileUpdateModel copyWith({AdminStatus? status}) {
    return AdminProfileUpdateModel(
      id: id,
      vendorId: vendorId,
      storeName: storeName,
      oldData: oldData,
      newData: newData,
      status: status ?? this.status,
      submittedAt: submittedAt,
    );
  }
}

class AdminProductModel {
  final String id;
  final String vendorName;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final AdminStatus status;

  const AdminProductModel({
    required this.id,
    required this.vendorName,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.status,
  });

  AdminProductModel copyWith({AdminStatus? status}) {
    return AdminProductModel(
      id: id,
      vendorName: vendorName,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      status: status ?? this.status,
    );
  }
}

class AdminGalleryModel {
  final String id;
  final String vendorName;
  final String title;
  final String imageUrl;
  final AdminStatus status;
  final String uploadedAt;

  const AdminGalleryModel({
    required this.id,
    required this.vendorName,
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.uploadedAt,
  });

  AdminGalleryModel copyWith({AdminStatus? status}) {
    return AdminGalleryModel(
      id: id,
      vendorName: vendorName,
      title: title,
      imageUrl: imageUrl,
      status: status ?? this.status,
      uploadedAt: uploadedAt,
    );
  }
}

class AdminOfferModel {
  final String id;
  final String vendorName;
  final String title;
  final String code;
  final int discountPercentage;
  final String validUntil;
  final AdminStatus status;

  const AdminOfferModel({
    required this.id,
    required this.vendorName,
    required this.title,
    required this.code,
    required this.discountPercentage,
    required this.validUntil,
    required this.status,
  });

  AdminOfferModel copyWith({AdminStatus? status}) {
    return AdminOfferModel(
      id: id,
      vendorName: vendorName,
      title: title,
      code: code,
      discountPercentage: discountPercentage,
      validUntil: validUntil,
      status: status ?? this.status,
    );
  }
}

class AdminCustomerModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String city;
  final int totalInquiries;
  final int totalOrders;
  final bool isBlocked;
  final String joinedAt;
  final List<String> recentActivity;

  const AdminCustomerModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.totalInquiries,
    required this.totalOrders,
    required this.isBlocked,
    required this.joinedAt,
    required this.recentActivity,
  });

  AdminCustomerModel copyWith({bool? isBlocked}) {
    return AdminCustomerModel(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      city: city,
      totalInquiries: totalInquiries,
      totalOrders: totalOrders,
      isBlocked: isBlocked ?? this.isBlocked,
      joinedAt: joinedAt,
      recentActivity: recentActivity,
    );
  }
}

class AdminReviewModel {
  final String id;
  final String vendorName;
  final String customerName;
  final double rating;
  final String comment;
  final bool isReported;
  final String? reportReason;
  final AdminStatus status;
  final String date;

  const AdminReviewModel({
    required this.id,
    required this.vendorName,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.isReported,
    this.reportReason,
    required this.status,
    required this.date,
  });

  AdminReviewModel copyWith({AdminStatus? status, bool? isReported}) {
    return AdminReviewModel(
      id: id,
      vendorName: vendorName,
      customerName: customerName,
      rating: rating,
      comment: comment,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason,
      status: status ?? this.status,
      date: date,
    );
  }
}

class AdminCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int vendorCount;
  final int displayOrder;
  final bool isActive;

  const AdminCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.vendorCount,
    required this.displayOrder,
    required this.isActive,
  });

  AdminCategoryModel copyWith({
    String? name,
    String? iconName,
    int? vendorCount,
    int? displayOrder,
    bool? isActive,
  }) {
    return AdminCategoryModel(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      vendorCount: vendorCount ?? this.vendorCount,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminNotificationItem {
  final String id;
  final String title;
  final String body;
  final String targetGroup; // All Users, Vendors, Individual Vendor
  final String sentAt;

  const AdminNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.targetGroup,
    required this.sentAt,
  });
}
