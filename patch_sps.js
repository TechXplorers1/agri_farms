const fs = require('fs');
const path = require('path');

const file = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\service_providers_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// Replace static distances in mapping
content = content.replace(/distance: '2-5 km',/g, "distance: '2-5 km',\n          latitude: (v['latitude'] as num?)?.toDouble(),\n          longitude: (v['longitude'] as num?)?.toDouble(),");
content = content.replace(/distance: '1-3 km',/g, "distance: '1-3 km',\n          latitude: (e['latitude'] as num?)?.toDouble(),\n          longitude: (e['longitude'] as num?)?.toDouble(),");
content = content.replace(/distance: 'Nearby',/g, "distance: 'Nearby',\n           latitude: (s['latitude'] as num?)?.toDouble(),\n           longitude: (s['longitude'] as num?)?.toDouble(),");
content = content.replace(/distance: '2 km',/g, "distance: '2 km',\n             latitude: (w['latitude'] as num?)?.toDouble(),\n             longitude: (w['longitude'] as num?)?.toDouble(),");

fs.writeFileSync(file, content);
console.log('Updated service_providers_screen.dart mapping');
