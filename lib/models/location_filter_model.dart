class LocationFilterModel {
  final String name;
  final String displayName;
  final double? latitude;
  final double? longitude;
  final String? village;
  final String? mandal;
  final String? district;
  final String? state;
  final String? pincode;
  final bool isCurrentLocation;

  const LocationFilterModel({
    required this.name,
    String? displayName,
    this.latitude,
    this.longitude,
    this.village,
    this.mandal,
    this.district,
    this.state,
    this.pincode,
    this.isCurrentLocation = false,
  }) : displayName = displayName ?? name;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory LocationFilterModel.currentLocation({
    required String name,
    String? displayName,
    double? latitude,
    double? longitude,
    String? village,
    String? mandal,
    String? district,
    String? state,
    String? pincode,
  }) {
    return LocationFilterModel(
      name: name,
      displayName: displayName ?? name,
      latitude: latitude,
      longitude: longitude,
      village: village,
      mandal: mandal,
      district: district,
      state: state,
      pincode: pincode,
      isCurrentLocation: true,
    );
  }

  factory LocationFilterModel.custom({
    required String name,
    String? displayName,
    double? latitude,
    double? longitude,
    String? village,
    String? mandal,
    String? district,
    String? state,
    String? pincode,
  }) {
    return LocationFilterModel(
      name: name,
      displayName: displayName ?? name,
      latitude: latitude,
      longitude: longitude,
      village: village,
      mandal: mandal,
      district: district,
      state: state,
      pincode: pincode,
      isCurrentLocation: false,
    );
  }

  @override
  String toString() => 'LocationFilterModel(name: $name, displayName: $displayName, lat: $latitude, lng: $longitude, current: $isCurrentLocation)';
}
