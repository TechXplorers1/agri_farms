const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

const oldCode = `                      _buildTextField(
                        AppLocalizations.of(context)!.locationLabel, 
                        _locationController, 
                        'e.g. Rampur, Nagpur',
                        icon: Icons.location_on_rounded,
                        suffixIcon: _isFetchingLocation 
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                              onPressed: _fetchCurrentLocation,
                            ),
                      ),`;

const newCode = `                      _buildTextField(
                        AppLocalizations.of(context)!.locationLabel, 
                        _locationController, 
                        'e.g. Rampur, Nagpur',
                        icon: Icons.location_on_rounded,
                        suffixIcon: _isFetchingLocation 
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                              onPressed: _fetchCurrentLocation,
                            ),
                      ),
                      const SizedBox(height: 20),
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
                      _buildTextField('Country', _countryController, 'Country Name'),`;

content = content.replace(oldCode, newCode);
fs.writeFileSync(filePath, content);
