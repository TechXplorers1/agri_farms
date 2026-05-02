const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const oldCode = `        setState(() {
           _locationController.text = "$village, $district";
        });`;

const newCode = `        setState(() {
           _locationController.text = "$village, $district";
           _villageController.text = village;
           _districtController.text = district;
           _streetController.text = place.street ?? '';
           _stateController.text = place.administrativeArea ?? '';
           _countryController.text = place.country ?? 'India';
           _pincodeController.text = place.postalCode ?? '';
        });`;

content = content.replace(oldCode, newCode);
fs.writeFileSync(filePath, content);
