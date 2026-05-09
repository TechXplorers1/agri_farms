const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_profile_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const oldCode = `                        Row(
                          children: [
                            Expanded(child: _buildTextField(_villageController, 'Village', 'Village name...', Icons.landscape_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_districtController, 'District', 'District name...', Icons.location_city_rounded)),
                          ],
                        ),`;

const newCode = `                        Row(
                          children: [
                            Expanded(child: _buildTextField(_houseNoController, 'H.No', 'e.g. 123', Icons.home_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_streetController, 'Street', 'Street name...', Icons.map_rounded)),
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
                            Expanded(child: _buildTextField(_pincodeController, 'Pincode', '6-digit code', Icons.pin_drop_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_countryController, 'Country', 'Country name...', Icons.public_rounded),`;

content = content.replace(oldCode, newCode);
fs.writeFileSync(filePath, content);
