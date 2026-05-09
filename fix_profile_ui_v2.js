const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_profile_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Match the row containing village controller
const regex = /Row\(\s*children: \[\s*Expanded\(child: _buildTextField\(_villageController, 'Village', 'Village name...', Icons\.landscape_rounded\)\),\s*const SizedBox\(width: 16\),\s*Expanded\(child: _buildTextField\(_districtController, 'District', 'District name...', Icons\.location_city_rounded\)\),\s*\]\s*,\s*\),/g;

const replacement = `Row(
                          children: [
                            Expanded(child: _buildTextField(_houseNoController, 'House No', 'H.No...', Icons.home_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_streetController, 'Street', 'Street name...', Icons.add_road_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_villageController, 'Village', 'Village name...', Icons.landscape_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_districtController, 'District', 'District name...', Icons.location_city_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_stateController, 'State', 'State name...', Icons.map_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_pincodeController, 'Pincode', 'Zip code...', Icons.pin_drop_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_countryController, 'Country', 'Country name...', Icons.public_rounded),
                        const SizedBox(height: 20),`;

if (regex.test(content)) {
    content = content.replace(regex, replacement);
    fs.writeFileSync(filePath, content);
    console.log("Success");
} else {
    console.log("Regex not found");
}
