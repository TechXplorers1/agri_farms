const fs = require('fs');
const path = require('path');

const file = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\service_providers_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// Add import
if (!content.includes('package:geolocator/geolocator.dart')) {
    content = content.replace(/import 'package:flutter\/material.dart';/, "import 'package:flutter/material.dart';\nimport 'package:geolocator/geolocator.dart';");
}

// Add location calc logic at end of _fetchProviders
const distanceCalcLogic = `
      // Calculate Exact Distances
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
                  p.distance = '\${distMeters.toStringAsFixed(0)} m';
                } else {
                  p.distance = '\${(distMeters / 1000).toStringAsFixed(1)} km';
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
        debugPrint('Error calculating distances: \$e');
      }
      
      return providers;
`;

content = content.replace(/return providers;/, distanceCalcLogic);

fs.writeFileSync(file, content);
console.log('Updated service_providers_screen.dart with distance calculation');
