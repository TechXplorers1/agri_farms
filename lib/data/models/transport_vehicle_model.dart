class TransportVehicle {
  final String? vehicleId;
  final String ownerId;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? loadCapacity;
  final double? pricePerKmOrTrip;
  final bool? driverIncluded;
  final String? location;
  final bool? isAvailable;
  final String? imageUrl;
  final double? rating;

  TransportVehicle({
    this.vehicleId,
    required this.ownerId,
    this.vehicleType,
    this.vehicleNumber,
    this.loadCapacity,
    this.pricePerKmOrTrip,
    this.driverIncluded,
    this.location,
    this.isAvailable,
    this.imageUrl,
    this.rating,
  });

  factory TransportVehicle.fromJson(Map<String, dynamic> json) {
    return TransportVehicle(
      vehicleId: json['vehicleId'],
      ownerId: json['ownerId'] ?? '',
      vehicleType: json['vehicleType'],
      vehicleNumber: json['vehicleNumber'],
      loadCapacity: json['loadCapacity'],
      pricePerKmOrTrip: (json['pricePerKmOrTrip'] as num?)?.toDouble(),
      driverIncluded: json['driverIncluded'],
      location: json['location'],
      isAvailable: json['isAvailable'],
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'ownerId': ownerId,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'loadCapacity': loadCapacity,
      'pricePerKmOrTrip': pricePerKmOrTrip,
      'driverIncluded': driverIncluded,
      'location': location,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}
