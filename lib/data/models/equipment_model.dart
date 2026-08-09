class Equipment {
  final String? equipmentId;
  final String ownerId;
  final String? category;
  final String? brandModel;
  final double? pricePerHour;
  final bool? operatorAvailable;
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
  final double? operatorPrice;
  final String? ownerBusinessName;
  final String? ownerName;
  final String? attachedEquipments;
  final String? description;
  final String? brand;
  final String? model;
  final String? vehicleNumber;
  final int? jobsCompleted;

  Equipment({
    this.equipmentId,
    required this.ownerId,
    this.category,
    this.brandModel,
    this.pricePerHour,
    this.operatorAvailable,
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
    this.operatorPrice,
    this.ownerBusinessName,
    this.ownerName,
    this.attachedEquipments,
    this.description,
    this.brand,
    this.model,
    this.vehicleNumber,
    this.jobsCompleted,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      equipmentId: json['equipmentId'],
      ownerId: json['ownerId'] ?? '',
      category: json['category'],
      brandModel: json['brandModel'],
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      operatorAvailable: json['operatorAvailable'],
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
      operatorPrice: (json['operatorPrice'] as num?)?.toDouble(),
      ownerBusinessName: json['ownerBusinessName'],
      ownerName: json['ownerName'],
      attachedEquipments: json['attachedEquipments'],
      description: json['description'],
      brand: json['brand'],
      model: json['model'],
      vehicleNumber: json['vehicleNumber'],
      jobsCompleted: json['jobsCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'ownerId': ownerId,
      'category': category,
      'brandModel': brandModel,
      'pricePerHour': pricePerHour,
      'operatorAvailable': operatorAvailable,
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
      'operatorPrice': operatorPrice,
      'ownerBusinessName': ownerBusinessName,
      'ownerName': ownerName,
      'attachedEquipments': attachedEquipments,
      'description': description,
      'brand': brand,
      'model': model,
      'vehicleNumber': vehicleNumber,
      'jobsCompleted': jobsCompleted,
    };
  }
}
