class TransportVehicle {
  final String? vehicleId;
  final String ownerId;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? loadCapacity;
  final double? pricePerKmOrTrip;
  final bool? driverIncluded;
  final String? location;
  String? houseNo;
  String? street;
  String? village;
  String? district;
  String? state;
  String? country;
  String? pincode;
  double? latitude;
  double? longitude;
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
    this.houseNo,
    this.street,
    this.village,
    this.district,
    this.state,
    this.country,
    this.pincode,
    this.latitude,
    this.longitude,
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
      houseNo: json['houseNo'],
      street: json['street'],
      village: json['village'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
      'houseNo': houseNo,
      'street': street,
      'village': village,
      'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}
