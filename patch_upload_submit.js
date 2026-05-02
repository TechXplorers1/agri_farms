const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const addressMapFields = `
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,`;

// Equipment
content = content.replace(
    /'location': _locationController\.text,/,
    `'location': _locationController.text,${addressMapFields}`
);

// Note: the previous replacement might match multiple if they are identical.
// Let's use more specific replacements if possible.

// FarmWorker
content = content.replace(
    /'location': _locationController\.text,/, // 2nd occurrence (if any)
    `'location': _locationController.text,${addressMapFields}`
);

// Transport
content = content.replace(
    /'location': _locationController\.text,/, // 3rd occurrence
    `'location': _locationController.text,${addressMapFields}`
);

// Service
content = content.replace(
    /'location': _locationController\.text,/, // 4th occurrence
    `'location': _locationController.text,${addressMapFields}`
);

// Since replace(string, newstring) only replaces the first occurrence, I can just repeat it for each occurrence if they are the same.
// But wait, it's safer to use a global replace if they are all the same and all need updating.

content = content.replace(/'location': _locationController\.text,/g, `'location': _locationController.text,${addressMapFields}`);

fs.writeFileSync(filePath, content);
