const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_registered_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Update _fetchCurrentLocation
const newFetchLogic = `
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      
      if (mounted) {
        setState(() {
           _locationController.text = "\$village, \$district";
        });
        
        UiUtils.showCenteredToast(context, 'Location detected: \$village, \$district');
      }
`;

content = content.replace(/Position position = await Geolocator\.getCurrentPosition\([\s\S]*?UiUtils\.showCenteredToast\(context, 'Location detected: \$village, \$district'\);\s*\}\s*\}/, newFetchLogic + "\n    }");

fs.writeFileSync(filePath, content);
