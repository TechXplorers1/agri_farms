const fs = require('fs');
const path = require('path');

const file = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// Add variables
if (!content.includes('double _selectedLatitude = 0.0;')) {
    content = content.replace('bool _isFetchingLocation = false;', 'bool _isFetchingLocation = false;\n  double _selectedLatitude = 0.0;\n  double _selectedLongitude = 0.0;');
}

// Update fetch location
content = content.replace('final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);', 'setState(() {\n        _selectedLatitude = position.latitude;\n        _selectedLongitude = position.longitude;\n      });\n\n      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);');

// Add to payloads
content = content.replace(/'location': _locationController\.text\.isNotEmpty \? _locationController\.text : 'Local',/g, "'location': _locationController.text.isNotEmpty ? _locationController.text : 'Local',\n        'latitude': _selectedLatitude,\n        'longitude': _selectedLongitude,");
content = content.replace(/'location': _locationController\.text,/g, "'location': _locationController.text,\n        'latitude': _selectedLatitude,\n        'longitude': _selectedLongitude,");

// Also replace 'location': _locationController.text.isNotEmpty ? _locationController.text : 'Unknown',
content = content.replace(/'location': _locationController\.text\.isNotEmpty \? _locationController\.text : 'Unknown',/g, "'location': _locationController.text.isNotEmpty ? _locationController.text : 'Unknown',\n        'latitude': _selectedLatitude,\n        'longitude': _selectedLongitude,");

fs.writeFileSync(file, content);
console.log('Updated upload_item_screen.dart');
