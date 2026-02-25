class BookingDTO {
  String? bookingId;
  String? farmerId;
  String? providerId;
  String? assetId;
  String? assetType; // e.g., 'Transport', 'Equipment', 'Service', 'Worker'
  DateTime? bookingDate;
  DateTime? scheduledStartTime;
  DateTime? scheduledEndTime;
  String? status;
  double? totalAmount;
  double? locationLat;
  double? locationLng;
  String? addressText;
  String? notes; // JSON string containing specific booking details

  BookingDTO({
    this.bookingId,
    this.farmerId,
    this.providerId,
    this.assetId,
    this.assetType,
    this.bookingDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.status,
    this.totalAmount,
    this.locationLat,
    this.locationLng,
    this.addressText,
    this.notes,
  });

  factory BookingDTO.fromJson(Map<String, dynamic> json) {
    return BookingDTO(
      bookingId: json['bookingId'],
      farmerId: json['farmerId'],
      providerId: json['providerId'],
      assetId: json['assetId'],
      assetType: json['assetType'],
      bookingDate: json['bookingDate'] != null ? DateTime.parse(json['bookingDate']) : null,
      scheduledStartTime: json['scheduledStartTime'] != null ? DateTime.parse(json['scheduledStartTime']) : null,
      scheduledEndTime: json['scheduledEndTime'] != null ? DateTime.parse(json['scheduledEndTime']) : null,
      status: json['status'],
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : null,
      locationLat: json['locationLat'] != null ? (json['locationLat'] as num).toDouble() : null,
      locationLng: json['locationLng'] != null ? (json['locationLng'] as num).toDouble() : null,
      addressText: json['addressText'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'farmerId': farmerId,
      'providerId': providerId,
      'assetId': assetId,
      'assetType': assetType,
      'bookingDate': bookingDate?.toIso8601String(),
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'scheduledEndTime': scheduledEndTime?.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'addressText': addressText,
      'notes': notes,
    };
  }
}
