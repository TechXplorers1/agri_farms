const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const newAddressFields = `
                      Row(
                        children: [
                          Expanded(child: _buildTextField('H.No', _houseNoController, 'e.g. 123', icon: Icons.home_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Street', _streetController, 'Street Name', icon: Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Village', _villageController, 'Village Name', icon: Icons.location_city_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('District', _districtController, 'District Name')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('State', _stateController, 'State Name')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Pincode', _pincodeController, '6-digit code', keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Country', _countryController, 'Country Name'),
                      const SizedBox(height: 20),`;

// Match the location field specifically
const locationFieldPattern = /_buildTextField\(\s*AppLocalizations\.of\(context\)!\.locationLabel,\s*_locationController,[\s\S]+?onPressed:\s*_fetchCurrentLocation,[\s\S]+?\),/g;

content = content.replace(locationFieldPattern, (match) => match + newAddressFields);

fs.writeFileSync(filePath, content);
