class ServiceOffering {
  final String? serviceId;
  final String ownerId;
  final String? serviceType;
  final String? businessName;
  final String? description;
  final double? priceRate;
  final String? location;
  final bool? isAvailable;
  final String? imageUrl;
  final String? priceUnit; 
  final double? rating;

  ServiceOffering({
    this.serviceId,
    required this.ownerId,
    this.serviceType,
    this.businessName,
    this.description,
    this.priceRate,
    this.location,
    this.isAvailable,
    this.imageUrl,
    this.priceUnit,
    this.rating,
  });

  factory ServiceOffering.fromJson(Map<String, dynamic> json) {
    return ServiceOffering(
      serviceId: json['serviceId'],
      ownerId: json['ownerId'] ?? '',
      serviceType: json['serviceType'],
      businessName: json['businessName'],
      description: json['description'],
      priceRate: (json['priceRate'] as num?)?.toDouble(),
      location: json['location'],
      isAvailable: json['isAvailable'],
      imageUrl: json['imageUrl'],
      priceUnit: json['priceUnit'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serviceId != null) 'serviceId': serviceId,
      'ownerId': ownerId,
      if (serviceType != null) 'serviceType': serviceType,
      if (businessName != null) 'businessName': businessName,
      if (description != null) 'description': description,
      if (priceRate != null) 'priceRate': priceRate,
      if (location != null) 'location': location,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (priceUnit != null) 'priceUnit': priceUnit,
      if (rating != null) 'rating': rating,
    };
  }
}
