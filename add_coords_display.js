const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_profile_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add state variables for display
if (!content.includes("_detectedLat")) {
    content = content.replace("bool _isUploading = false;", "bool _isUploading = false;\n  double? _detectedLat;\n  double? _detectedLng;");
}

// Update the save logic to set these variables
if (!content.includes("_detectedLat = lat;")) {
    content = content.replace("debugPrint(\"Geocoding success: $lat, $lng\");", "debugPrint(\"Geocoding success: $lat, $lng\");\n            setState(() {\n              _detectedLat = lat;\n              _detectedLng = lng;\n            });");
}

// Add UI element to show coordinates
const coordsWidget = `
                        if (_detectedLat != null && _detectedLng != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                Text(
                                  "Coordinates: \${_detectedLat!.toStringAsFixed(6)}, \${_detectedLng!.toStringAsFixed(6)}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ],`;

// Insert the widget before the Country field
if (!content.includes("GPS Fixed")) {
    content = content.replace("_buildTextField(_countryController, 'Country'", coordsWidget + "\n                        _buildTextField(_countryController, 'Country'");
}

fs.writeFileSync(filePath, content);
