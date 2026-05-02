const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\service_providers_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// 1. Add _selectedDistance state variable
content = content.replace("String? _selectedLocation;", "String? _selectedLocation;\n  double? _selectedDistance;");

// 2. Define the distance options
const distanceOptions = "['5 km', '10 km', '15 km', '20 km', '25 km', '30 km', '35 km', '40 km', '45 km', '50 km', '55 km', '60 km']";

// 3. Update the filtering logic inside the build method
const filterLogicPattern = /final filteredProviders = allProviders\.where\(\(provider\) \{[\s\S]*?return matchesMake && matchesLocation;\s*\}\)\.toList\(\);/;
const newFilterLogic = `final filteredProviders = allProviders.where((provider) {
            bool matchesMake = true;
            bool matchesLocation = true;
            bool matchesDistance = true;

            if (_selectedMake != null && _selectedMake != 'All') {
               if (provider is EquipmentListing) matchesMake = provider.brandModel.contains(_selectedMake!); 
               else if (provider is TransportListing) matchesMake = provider.vehicleType.contains(_selectedMake!) || provider.name.contains(_selectedMake!);
               else if (provider is ServiceListing) matchesMake = provider.equipmentUsed.contains(_selectedMake!);
            }

            if (_selectedLocation != null && _selectedLocation != 'All') {
              if (_selectedLocation!.endsWith(' km')) {
                // Distance filtering
                double maxDist = double.parse(_selectedLocation!.split(' ')[0]);
                // Parse provider distance (e.g., "3.5 km")
                double? pDist;
                try {
                  String dStr = provider.distance.replaceAll(RegExp(r'[^0-9.]'), '');
                  pDist = double.tryParse(dStr);
                  // If "m", convert to km
                  if (provider.distance.contains(' m')) pDist = pDist! / 1000;
                } catch(_) {}
                
                if (pDist != null) {
                  matchesDistance = pDist <= maxDist;
                } else {
                  matchesDistance = false; // Exclude if distance unknown
                }
              } else {
                // Village/Location filtering
                matchesLocation = provider.location == _selectedLocation;
              }
            }
            return matchesMake && matchesLocation && matchesDistance;
          }).toList();`;

content = content.replace(filterLogicPattern, newFilterLogic);

// 4. Update the dropdown items in _buildFilterSection
const dropdownItemsPattern = /items: \['All', \.\.\.locations\],/;
const newDropdownItems = `items: ['All', ...${distanceOptions}, ...locations],`;

content = content.replace(dropdownItemsPattern, newDropdownItems);

fs.writeFileSync(filePath, content);
