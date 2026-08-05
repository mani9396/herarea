enum EnquiryStatus {
  open('OPEN', 'Open Inquiry'),
  responded('RESPONDED', 'Studio Responded'),
  orderPlaced('ORDER_PLACED', 'Order Confirmed'),
  closed('CLOSED', 'Closed');

  final String code;
  final String label;

  const EnquiryStatus(this.code, this.label);

  static EnquiryStatus fromCode(String? code) {
    return EnquiryStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code?.toUpperCase(),
      orElse: () => EnquiryStatus.open,
    );
  }
}

class EnquiryModel {
  final String id;
  final String productId;
  final String productTitle;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String requestedColor;
  final String requestedSize;
  final String? customerMessage;
  final String? studioResponse;
  final double? quotedPrice;
  final EnquiryStatus status;
  final String createdAt;

  const EnquiryModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.requestedColor,
    required this.requestedSize,
    this.customerMessage,
    this.studioResponse,
    this.quotedPrice,
    required this.status,
    required this.createdAt,
  });

  factory EnquiryModel.fromJson(Map<String, dynamic> json) {
    return EnquiryModel(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? json['product_id']?.toString() ?? '',
      productTitle: json['product_title'] ?? 'Bespoke Lehenga',
      storeId: json['store']?.toString() ?? json['store_id']?.toString() ?? '',
      storeName: json['store_name'] ?? 'HER AREA Partner Studio',
      customerId: json['customer']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? 'Couture Client',
      customerPhone: json['customer_phone'] ?? '+91 93333 33331',
      requestedColor: json['requested_color'] ?? 'Ruby Red',
      requestedSize: json['requested_size'] ?? 'Custom Fitting',
      customerMessage: json['customer_message'] ?? json['message'],
      studioResponse: json['studio_response'] ?? json['response'],
      quotedPrice: (json['quoted_price'] as num?)?.toDouble(),
      status: EnquiryStatus.fromCode(json['status']?.toString()),
      createdAt: json['created_at']?.toString().substring(0, 10) ?? '2026-08-01',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_title': productTitle,
      'store_id': storeId,
      'store_name': storeName,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'requested_color': requestedColor,
      'requested_size': requestedSize,
      'customer_message': customerMessage,
      'studio_response': studioResponse,
      'quoted_price': quotedPrice,
      'status': status.code,
      'created_at': createdAt,
    };
  }

  EnquiryModel copyWithStudioResponse({String? studioResponse, double? quotedPrice, EnquiryStatus? status}) {
    return EnquiryModel(
      id: id,
      productId: productId,
      productTitle: productTitle,
      storeId: storeId,
      storeName: storeName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      requestedColor: requestedColor,
      requestedSize: requestedSize,
      customerMessage: customerMessage,
      studioResponse: studioResponse ?? this.studioResponse,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
