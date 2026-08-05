enum BookingStatus {
  pending('PENDING', 'Pending Studio Confirmation'),
  confirmed('CONFIRMED', 'Confirmed'),
  rescheduled('RESCHEDULED', 'Rescheduled'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  final String code;
  final String label;

  const BookingStatus(this.code, this.label);

  static BookingStatus fromCode(String? code) {
    return BookingStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code?.toUpperCase(),
      orElse: () => BookingStatus.pending,
    );
  }
}

class BookingModel {
  final String id;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceId;
  final String serviceTitle;
  final double servicePrice;
  final String bookingDate; // YYYY-MM-DD
  final String timeSlot; // e.g. 10:00 AM - 11:00 AM
  final BookingStatus status;
  final String? specialNotes;
  final String? adminInterventionReason;

  const BookingModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceId,
    required this.serviceTitle,
    required this.servicePrice,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
    this.specialNotes,
    this.adminInterventionReason,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      storeId: json['store']?.toString() ?? json['store_id']?.toString() ?? '',
      storeName: json['store_name'] ?? 'HER AREA Showroom',
      customerId: json['customer']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? 'VIP Client',
      customerPhone: json['customer_phone'] ?? '+91 93333 33333',
      serviceId: json['service']?.toString() ?? json['service_id']?.toString() ?? '',
      serviceTitle: json['service_title'] ?? 'Bridal Styling Consultation',
      servicePrice: (json['service_price'] as num?)?.toDouble() ?? 1500.0,
      bookingDate: json['booking_date']?.toString() ?? '2026-08-05',
      timeSlot: json['time_slot'] ?? '11:00 AM',
      status: BookingStatus.fromCode(json['status']?.toString()),
      specialNotes: json['special_notes'] ?? json['notes'],
      adminInterventionReason: json['admin_intervention_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'store_name': storeName,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_id': serviceId,
      'service_title': serviceTitle,
      'service_price': servicePrice,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'status': status.code,
      'special_notes': specialNotes,
      'admin_intervention_reason': adminInterventionReason,
    };
  }

  BookingModel copyWithStatus(BookingStatus newStatus) {
    return BookingModel(
      id: id,
      storeId: storeId,
      storeName: storeName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      servicePrice: servicePrice,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      status: newStatus,
      specialNotes: specialNotes,
      adminInterventionReason: adminInterventionReason,
    );
  }
}
