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
  String? cancelledBy;
  String? cancellationReason;

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
    this.cancelledBy,
    this.cancellationReason,
  });

  static DateTime? _parseDateTime(dynamic jsonVal) {
    if (jsonVal == null) return null;
    try {
      String str = jsonVal.toString();
      if (!str.endsWith('Z') && !str.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
        str += 'Z';
      }
      return DateTime.parse(str).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(jsonVal.toString()).toLocal();
      } catch (e) {
        return null;
      }
    }
  }

  factory BookingDTO.fromJson(Map<String, dynamic> json) {
    return BookingDTO(
      bookingId: json['bookingId'],
      farmerId: json['farmerId'],
      providerId: json['providerId'],
      assetId: json['assetId'],
      assetType: json['assetType'],
      bookingDate: _parseDateTime(json['bookingDate']),
      scheduledStartTime: _parseDateTime(json['scheduledStartTime']),
      scheduledEndTime: _parseDateTime(json['scheduledEndTime']),
      status: json['status'],
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : null,
      locationLat: json['locationLat'] != null ? (json['locationLat'] as num).toDouble() : null,
      locationLng: json['locationLng'] != null ? (json['locationLng'] as num).toDouble() : null,
      addressText: json['addressText'],
      notes: json['notes'],
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'farmerId': farmerId,
      'providerId': providerId,
      'assetId': assetId,
      'assetType': assetType,
      'bookingDate': bookingDate?.toUtc().toIso8601String(),
      'scheduledStartTime': scheduledStartTime?.toUtc().toIso8601String(),
      'scheduledEndTime': scheduledEndTime?.toUtc().toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'addressText': addressText,
      'notes': notes,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
    };
  }
}
