const fs = require('fs');
const path = require('path');

const modelsDir = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\data\\models';
const files = fs.readdirSync(modelsDir);

files.forEach(file => {
    if (!file.endsWith('_model.dart')) return;
    const filePath = path.join(modelsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');
    
    if (!content.includes('String? houseNo')) {
        // Fields
        content = content.replace(
            /String\? location;/,
            `String? location;\n  String? houseNo;\n  String? street;\n  String? village;\n  String? district;\n  String? state;\n  String? country;\n  String? pincode;`
        );
        
        // Constructor
        content = content.replace(
            /this\.location,/,
            `this.location,\n    this.houseNo,\n    this.street,\n    this.village,\n    this.district,\n    this.state,\n    this.country,\n    this.pincode,`
        );
        
        // fromJson
        content = content.replace(
            /location: json\['location'\],/,
            `location: json['location'],\n      houseNo: json['houseNo'],\n      street: json['street'],\n      village: json['village'],\n      district: json['district'],\n      state: json['state'],\n      country: json['country'],\n      pincode: json['pincode'],`
        );
        
        // toJson
        content = content.replace(
            /'location': location,/,
            `'location': location,\n      'houseNo': houseNo,\n      'street': street,\n      'village': village,\n      'district': district,\n      'state': state,\n      'country': country,\n      'pincode': pincode,`
        );
        
        fs.writeFileSync(filePath, content);
        console.log(`Updated ${file}`);
    }
});
