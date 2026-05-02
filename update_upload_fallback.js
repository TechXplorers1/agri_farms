const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Update _updateCoordinatesFromAddress helper
const newGeocodeCall = `
      // OS geocoding fallback
      if (lat == null || lng == null) {
        String fallbackAddress = "\${_villageController.text}, \${_districtController.text}, \${_stateController.text}, \${_countryController.text}";
        final coords = await GeocodingService.getCoordinates(fullAddress, fallbackAddress: fallbackAddress);
        if (coords != null) {
          lat = coords['latitude'];
          lng = coords['longitude'];
        }
      }
`;

content = content.replace(/\/\/ OS geocoding fallback[\s\S]*?lng = coords\['longitude'\];\s*\}\s*\}/, newGeocodeCall);

fs.writeFileSync(filePath, content);
