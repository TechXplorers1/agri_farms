class Equipment {
  final String? equipmentId;
  final String ownerId;
  final String? category;
  final String? brandModel;
  final double? pricePerHour;
  final bool? operatorAvailable;
  final String? location;
  final bool? isAvailable;
  final String? imageUrl;
  final double? rating;

  Equipment({
    this.equipmentId,
    required this.ownerId,
    this.category,
    this.brandModel,
    this.pricePerHour,
    this.operatorAvailable,
    this.location,
    this.isAvailable,
    this.imageUrl,
    this.rating,
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
      isAvailable: json['isAvailable'],
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
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
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}
