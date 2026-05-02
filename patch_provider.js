const fs = require('fs');
const path = require('path');

const file = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\utils\\provider_manager.dart';
let content = fs.readFileSync(file, 'utf8');

// Replace ServiceProvider
content = content.replace('final String distance;', 'String distance;\n  double? latitude;\n  double? longitude;');
content = content.replace('required this.distance,', 'required this.distance,\n    this.latitude,\n    this.longitude,');

// Replace subclasses constructors
content = content.replace(/required super\.distance,/g, 'required super.distance,\n    super.latitude,\n    super.longitude,');

// API mappings
content = content.replace(/distance: eq\.location \?\? 'Unknown',/g, "distance: eq.location ?? 'Unknown',\n            latitude: eq.latitude,\n            longitude: eq.longitude,");
content = content.replace(/distance: v\.location \?\? 'Unknown',/g, "distance: v.location ?? 'Unknown',\n            latitude: v.latitude,\n            longitude: v.longitude,");
content = content.replace(/distance: s\.location \?\? 'Unknown',/g, "distance: s.location ?? 'Unknown',\n            latitude: s.latitude,\n            longitude: s.longitude,");

fs.writeFileSync(file, content);
console.log('Fixed provider_manager.dart');
