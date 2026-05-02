const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\service_providers_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const distanceCalcOld = `      // Calculate Exact Distances
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            for (var p in providers) {
              if (p.latitude != null && p.longitude != null) {
                double distMeters = Geolocator.distanceBetween(position.latitude, position.longitude, p.latitude!, p.longitude!);
                if (distMeters < 1000) {
                  p.distance = '${distMeters.toStringAsFixed(0)} m';
                } else {
                  p.distance = '${(distMeters / 1000).toStringAsFixed(1)} km';
                }
              }
            }
            
            // Sort by distance
            providers.sort((a, b) {
              if (a.latitude == null && b.latitude == null) return 0;
              if (a.latitude == null) return 1;
              if (b.latitude == null) return -1;
              double distA = Geolocator.distanceBetween(position.latitude, position.longitude, a.latitude!, a.longitude!);
              double distB = Geolocator.distanceBetween(position.latitude, position.longitude, b.latitude!, b.longitude!);
              return distA.compareTo(distB);
            });
          }
        }
      } catch (e) {
        debugPrint('Error calculating distances: $e');
      }`;

const distanceCalcNew = `      // Calculate Exact Distances based on User Profile coordinates
      try {
        double? userLat;
        double? userLng;

        if (currentUserId != null) {
          final userData = await apiService.getUser(currentUserId);
          if (userData != null) {
            userLat = (userData['latitude'] as num?)?.toDouble();
            userLng = (userData['longitude'] as num?)?.toDouble();
          }
        }

        // Fallback to Geolocator if profile has no coordinates
        if (userLat == null || userLng == null) {
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (serviceEnabled) {
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                userLat = position.latitude;
                userLng = position.longitude;
              }
            }
        }

        if (userLat != null && userLng != null) {
            for (var p in providers) {
              if (p.latitude != null && p.longitude != null) {
                double distMeters = Geolocator.distanceBetween(userLat, userLng, p.latitude!, p.longitude!);
                if (distMeters < 1000) {
                  p.distance = \'\${distMeters.toStringAsFixed(0)} m\';
                } else {
                  p.distance = \'\${(distMeters / 1000).toStringAsFixed(1)} km\';
                }
              } else {
                 p.distance = 'Unknown';
              }
            }
            
            // Sort by distance
            providers.sort((a, b) {
              if (a.latitude == null && b.latitude == null) return 0;
              if (a.latitude == null) return 1;
              if (b.latitude == null) return -1;
              double distA = Geolocator.distanceBetween(userLat!, userLng!, a.latitude!, a.longitude!);
              double distB = Geolocator.distanceBetween(userLat, userLng, b.latitude!, b.longitude!);
              return distA.compareTo(distB);
            });
        }
      } catch (e) {
        debugPrint('Error calculating distances: $e');
      }`;

content = content.replace(distanceCalcOld, distanceCalcNew);

fs.writeFileSync(filePath, content);
