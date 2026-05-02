const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// The file has a lot of duplicate lines in the maps. Let's fix that while ensuring lat/lng are always present.

// Fix _submitEquipment map (it had like 5 sets of houseNo/street)
const equipmentMapPattern = /final equipmentData = \{[\s\S]*?latitude': _selectedLatitude,[\s\S]*?'longitude': _selectedLongitude,[\s\S]*?\};/;
const cleanEquipmentMap = `final equipmentData = {
        'ownerId': _userId,
        'category': _selectedEquipmentType,
        'brandModel': _brandModelController.text,
        'conditionStatus': _condition,
        'pricePerHour': parsedPrice,
        'operatorAvailable': _operatorAvailable,
        'location': _locationController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'isAvailable': true,
        'rating': 5.0,
        'approvalStatus': 'Pending',
        'imageUrl': await _uploadSelectedImage() ?? 'https://placehold.co/600x400?text=Equipment',
      };`;

content = content.replace(equipmentMapPattern, cleanEquipmentMap);

// Check _submitVehicle
if (!content.includes("'latitude': _selectedLatitude") && content.includes("_submitVehicle")) {
    // Add logic to submit vehicle
}

fs.writeFileSync(filePath, content);
