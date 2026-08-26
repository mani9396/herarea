class ListingPlanModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final bool isActive;

  const ListingPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.isActive,
  });

  factory ListingPlanModel.fromJson(Map<String, dynamic> json) {
    return ListingPlanModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      durationDays: int.tryParse(json['duration_days']?.toString() ?? '') ?? 30,
      isActive: json['is_active'] == true || json['is_active'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_days': durationDays,
      'is_active': isActive,
    };
  }
}

class VendorSubscriptionModel {
  final int id;
  final int? plan;
  final String planName;
  final int planDuration;
  final String status;
  final String? startDate;
  final String? endDate;
  final double? amountPaid;
  final String currency;
  final String? razorpayOrderId;
  final String createdAt;

  const VendorSubscriptionModel({
    required this.id,
    this.plan,
    required this.planName,
    required this.planDuration,
    required this.status,
    this.startDate,
    this.endDate,
    this.amountPaid,
    required this.currency,
    this.razorpayOrderId,
    required this.createdAt,
  });

  factory VendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? json['id'] as int? ?? 0,
      plan: json['plan'] != null ? (int.tryParse(json['plan']?.toString() ?? '') ?? json['plan'] as int?) : null,
      planName: json['plan_name']?.toString() ?? '',
      planDuration: int.tryParse(json['plan_duration']?.toString() ?? '') ?? json['plan_duration'] as int? ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      amountPaid: json['amount_paid'] != null ? (double.tryParse(json['amount_paid']?.toString() ?? '') ?? (json['amount_paid'] as num?)?.toDouble()) : null,
      currency: json['currency']?.toString() ?? 'INR',
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PaymentRecordModel {
  final int id;
  final int? subscription;
  final int? plan;
  final String planName;
  final double amount;
  final String currency;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String status;
  final String createdAt;
  final String? verifiedAt;

  const PaymentRecordModel({
    required this.id,
    this.subscription,
    this.plan,
    required this.planName,
    required this.amount,
    required this.currency,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as int? ?? 0,
      subscription: json['subscription'] as int?,
      plan: json['plan'] as int?,
      planName: json['plan_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      razorpayPaymentId: json['razorpay_payment_id']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['created_at']?.toString() ?? '',
      verifiedAt: json['verified_at']?.toString(),
    );
  }
}
