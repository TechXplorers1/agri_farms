const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_profile_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Update geocoding call with fallback
const newGeocodeCall = `
          // Fallback to OpenStreetMap for Windows/Web or if local fails
          if (lat == null || lng == null) {
            String fallbackAddress = "\${_villageController.text}, \${_districtController.text}, \${_stateController.text}, \${_countryController.text}";
            final coords = await GeocodingService.getCoordinates(fullAddress, fallbackAddress: fallbackAddress);
            if (coords != null) {
              lat = coords['latitude'];
              lng = coords['longitude'];
            }
          }
`;

content = content.replace(/\/\/ Fallback to OpenStreetMap for Windows\/Web or if local fails[\s\S]*?lng = coords\['longitude'\];\s*\}\s*\}/, newGeocodeCall);

fs.writeFileSync(filePath, content);
