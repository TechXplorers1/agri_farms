class Booking {
  final String? bookingId;
  final String farmerId;
  final String providerId;
  final String? assetId;
  final String? assetType;
  final String? status;
  final double? totalAmount;
  final String? bookingDate;

  Booking({
    this.bookingId,
    required this.farmerId,
    required this.providerId,
    this.assetId,
    this.assetType,
    this.status,
    this.totalAmount,
    this.bookingDate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'],
      farmerId: json['farmerId'] ?? '',
      providerId: json['providerId'] ?? '',
      assetId: json['assetId'],
      assetType: json['assetType'],
      status: json['status'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      bookingDate: json['bookingDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'farmerId': farmerId,
      'providerId': providerId,
      'assetId': assetId,
      'assetType': assetType,
      'status': status,
      'totalAmount': totalAmount,
      'bookingDate': bookingDate,
    };
  }
}
