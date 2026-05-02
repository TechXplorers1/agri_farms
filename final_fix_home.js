const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\home_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Identify the broken section
// It starts with position.longitude); and ends with _showManualLocationDialog();
const startMarker = "await prefs.setDouble('user_longitude', position.longitude);";
const endMarker = "_showManualLocationDialog();";

const startIndex = content.indexOf(startMarker);
const endIndex = content.indexOf(endMarker);

if (startIndex !== -1 && endIndex !== -1) {
    const head = content.substring(0, startIndex + startMarker.length);
    const tail = content.substring(endIndex);
    
    const middle = `
      
      if (mounted) {
        UiUtils.showCenteredToast(context, 'Location detected: $village, $district');
      }
    } catch (e) {
      UiUtils.showCenteredToast(context, 'Error fetching location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Choose Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _locationOption(Icons.my_location, Colors.blue, 'Auto Detect', 'Use GPS to find your location', !_isFetchingLocation, () async {
                  setModalState(() {});
                  await _fetchCurrentLocation();
                  if (context.mounted) Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _locationOption(Icons.location_city, Colors.orange, 'Enter Manually', 'Type your village/district', true, () {
                  Navigator.pop(context);
    `;
    
    fs.writeFileSync(filePath, head + middle + tail);
}
