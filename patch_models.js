const fs = require('fs');
const path = require('path');

const modelsDir = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\data\\models';
const files = fs.readdirSync(modelsDir);

files.forEach(file => {
    if (!file.endsWith('_model.dart')) return;
    const filePath = path.join(modelsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Check if double? latitude already exists
    if (!content.includes('double? latitude')) {
        // Add fields
        content = content.replace(/String\? location;/g, 'String? location;\n  double? latitude;\n  double? longitude;');
        
        // Add to constructor
        content = content.replace(/this\.location,/g, 'this.location,\n    this.latitude,\n    this.longitude,');
        
        // Add to fromJson
        content = content.replace(/location: json\['location'\],/g, "location: json['location'],\n      latitude: (json['latitude'] as num?)?.toDouble(),\n      longitude: (json['longitude'] as num?)?.toDouble(),");
        
        // Add to toJson
        content = content.replace(/'location': location,/g, "'location': location,\n      'latitude': latitude,\n      'longitude': longitude,");
        
        fs.writeFileSync(filePath, content);
        console.log(`Updated ${file}`);
    }
});
