import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/provider_manager.dart';

class UploadItemScreen extends StatefulWidget {
  final String category; // 'Transport', 'Equipment', 'Farm Workers', 'Ploughing' (future)

  const UploadItemScreen({super.key, required this.category});

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  // Common Controllers
  final TextEditingController _nameController = TextEditingController(); // Name / Title
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Transport Specific
  String? _selectedTransportType;
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController(); // New
  final TextEditingController _serviceAreaController = TextEditingController(); // New
  bool _fuelIncluded = true;
  bool _driverIncluded = true;

  // Equipment Specific
  String? _selectedEquipmentType; 
  final TextEditingController _brandModelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(); // New
  bool _operatorAvailable = false;
  String _condition = 'Good';

  // Farm Worker Specific
  final TextEditingController _maleCountController = TextEditingController();
  final TextEditingController _femaleCountController = TextEditingController();
  final TextEditingController _malePriceController = TextEditingController();
  final TextEditingController _femalePriceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController(); 
  
  // Service Specific (Ploughing, etc.)
  final TextEditingController _equipmentUsedController = TextEditingController(); // e.g., "John Deere 5310"
  bool _operatorIncludedService = true;

  // Mock Lists
  final List<String> _transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
  final List<String> _equipmentCategories = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys']; 
  final List<String> _serviceCategories = ['Ploughing', 'Harvesting', 'Drone Spraying', 'Irrigation', 'Soil Testing', 'Vet Care']; // For dropdown if category is generic 'Services' 
  
  final List<String> _conditions = ['New', 'Good', 'Average', 'Poor'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _vehicleNumberController.dispose();
    _serviceAreaController.dispose();
    _brandModelController.dispose();
    _yearController.dispose();
    _maleCountController.dispose();
    _femaleCountController.dispose();
    _malePriceController.dispose();
    _femalePriceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.category == 'Farm Workers') {
      _submitFarmWorker();
    } else if (widget.category == 'Transport') {
      _submitTransport();
    } else if (widget.category == 'Equipment') {
      _submitEquipment();
    } else {
      // Treat as generic service if not specific
      _submitService();
    }
  }

  void _submitFarmWorker() {
    if (_nameController.text.isEmpty || (_maleCountController.text.isEmpty && _femaleCountController.text.isEmpty)) {
      _showError('Please fill required fields');
      return;
    }

    final newProvider = FarmWorkerListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text, // Group Name
      serviceName: 'Farm Workers',
      distance: '0.5 km', // Mock
      rating: 5.0,
      approvalStatus: 'Pending',
      location: _locationController.text.isNotEmpty ? _locationController.text : 'Local',
      maleCount: int.tryParse(_maleCountController.text) ?? 0,
      femaleCount: int.tryParse(_femaleCountController.text) ?? 0,
      malePrice: int.tryParse(_malePriceController.text) ?? 0,
      femalePrice: int.tryParse(_femalePriceController.text) ?? 0,
      skills: _skillsController.text.isNotEmpty ? _skillsController.text : 'General Farm Work',
      image: 'https://placehold.co/600x400?text=Workers',
    );

    ProviderManager().addProvider(newProvider);
    _completeSubmission();
  }



  void _submitEquipment() {
    if (_selectedEquipmentType == null || _brandModelController.text.isEmpty || _priceController.text.isEmpty) {
       _showError('Please provide equipment details');
       return;
    }

    final newProvider = EquipmentListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isNotEmpty ? _nameController.text : 'Owner', // Owner name usually
      serviceName: _selectedEquipmentType!, // 'Tractors', 'Harvesters'
      distance: '1 km',
      rating: 5.0,
      approvalStatus: 'Pending',
      location: _locationController.text,
      brandModel: _brandModelController.text,
      price: _priceController.text,
      operatorAvailable: _operatorAvailable,
      condition: _condition,
      yearOfManufacture: _yearController.text.isNotEmpty ? _yearController.text : null,
      image: 'https://placehold.co/600x400?text=Equipment',
    );

    ProviderManager().addProvider(newProvider);
    _completeSubmission();
  }

  void _completeSubmission() {
    _upgradeUserToProvider();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing uploaded successfully! Pending Approval.'),
        backgroundColor: Color(0xFF00AA55),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _upgradeUserToProvider() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString('user_role', 'Owner');
  }

  String _getScreenTitle() {
    if (widget.category == 'Transport') return 'Add Vehicle';
    if (widget.category == 'Equipment') return 'Add Equipment';
    if (widget.category == 'Farm Workers') return 'Add Group';
    return 'Add ${widget.category}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Upload Placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                   const SizedBox(height: 8),
                   Text('Add Photos', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (widget.category == 'Farm Workers') _buildFarmWorkerForm(),
            if (widget.category == 'Transport') _buildTransportForm(),
            if (widget.category == 'Equipment') _buildEquipmentForm(),
            if (!['Farm Workers', 'Transport', 'Equipment'].contains(widget.category)) _buildServicesForm(),

            const SizedBox(height: 24),
             _buildTextField('Location (Village -> District)', _locationController, 'e.g. Rampur, Nagpur'),
            const SizedBox(height: 16),
             _buildTextField('Description (Optional)', _descriptionController, 'Any extra info...', maxLines: 3),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FORMS ---

  Widget _buildFarmWorkerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Group Details'),
        const SizedBox(height: 12),
        _buildTextField('Group Name / Leader Name', _nameController, 'e.g. Ramesh Labour Group'),
        const SizedBox(height: 16),
        _buildTextField('Skills', _skillsController, 'e.g. Sowing, Harvesting, Loading'),
        const SizedBox(height: 20),
        
        _buildSectionTitle('Staff & Pricing'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Male Workers', _maleCountController, 'Count', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
             Expanded(child: _buildTextField('Price/Male (₹)', _malePriceController, 'Daily Wage', keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
           children: [
            Expanded(child: _buildTextField('Female Workers', _femaleCountController, 'Count', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Price/Female (₹)', _femalePriceController, 'Daily Wage', keyboardType: TextInputType.number)),
          ],
        ),
      ],
    );
  }


  Widget _buildTransportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vehicle Details'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedTransportType,
          decoration: _inputDecoration('Vehicle Type'),
          items: _transportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedTransportType = v),
        ),
        const SizedBox(height: 16),
        _buildTextField('Vehicle Name / Title', _nameController, 'e.g. Mahindra Bolero Pickup'),
        const SizedBox(height: 16),
        _buildTextField('Vehicle Number (Optional/Private)', _vehicleNumberController, 'e.g. MH 40 AB 1234'),
        const SizedBox(height: 16),
        _buildTextField('Load Capacity', _capacityController, 'e.g. 1.5 Ton'),
        const SizedBox(height: 16),
        _buildTextField('Service Area', _serviceAreaController, 'e.g. Within 50km or specific districts'),
        
        const SizedBox(height: 20),
        _buildSectionTitle('Pricing & Availability'),
        const SizedBox(height: 12),
        _buildTextField('Price (No hidden charges)', _priceController, 'e.g. ₹20/km or ₹1000/trip', keyboardType: TextInputType.text),
        
        const SizedBox(height: 20),
        _buildSectionTitle('Options'),
        CheckboxListTile(
          title: const Text('Fuel Included'),
          value: _fuelIncluded,
          onChanged: (v) => setState(() => _fuelIncluded = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF00AA55),
        ),
        CheckboxListTile(
          title: const Text('Driver Included'),
          value: _driverIncluded,
          onChanged: (v) => setState(() => _driverIncluded = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
           activeColor: const Color(0xFF00AA55),
        ),
      ],
    );
  }

  void _submitTransport() {
    if (_selectedTransportType == null || _nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showError('Please select type and fill details');
      return;
    }

    final newProvider = TransportListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      serviceName: _selectedTransportType!, // Use selected type as service name key
      distance: '1 km',
      rating: 5.0,
      approvalStatus: 'Pending',
      location: _locationController.text,
      vehicleType: _selectedTransportType!,
      loadCapacity: _capacityController.text,
      price: _priceController.text,
      fuelIncluded: _fuelIncluded,
      driverIncluded: _driverIncluded,
      vehicleNumber: _vehicleNumberController.text.isNotEmpty ? _vehicleNumberController.text : null,
      serviceArea: _serviceAreaController.text.isNotEmpty ? _serviceAreaController.text : null,
      image: 'https://placehold.co/600x400?text=Vehicle',
    );
    
    ProviderManager().addProvider(newProvider);
    _completeSubmission();
  }

  void _submitService() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
       _showError('Please provide service details');
       return;
    }

    final newProvider = ServiceListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text, // Provider Name
      serviceName: widget.category, // e.g. 'Ploughing' passed from home screen
      distance: '1 km',
      rating: 5.0,
      approvalStatus: 'Pending',
      location: _locationController.text,
      equipmentUsed: _equipmentUsedController.text.isNotEmpty ? _equipmentUsedController.text : 'Standard Equipment',
      price: _priceController.text,
      operatorIncluded: _operatorIncludedService,
      jobsCompleted: 0,

      isAvailable: true,
      image: 'https://placehold.co/600x400?text=Service', 
    );

    ProviderManager().addProvider(newProvider);
    _completeSubmission();
  }

  // ... (existing _submitEquipment ...)

  Widget _buildServicesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Service Details'),
        const SizedBox(height: 12),
        // If category is generic 'Services', show dropdown? For now assuming fixed category passed
        Text('Service Type: ${widget.category}', style: const TextStyle(fontSize: 14, color: Colors.grey)), 
        const SizedBox(height: 16),
        _buildTextField('Provider Name / Business Name', _nameController, 'e.g. Ramesh Services'),
        const SizedBox(height: 16),
        _buildTextField('Equipment Used', _equipmentUsedController, 'e.g. John Deere Tractor + Plough'),
        
        const SizedBox(height: 20),
        _buildSectionTitle('Pricing & Terms'),
        const SizedBox(height: 12),
        _buildTextField('Price / Rate', _priceController, 'e.g. ₹1200 / acre'),
        
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Operator Included?'),
          value: _operatorIncludedService,
          onChanged: (v) => setState(() => _operatorIncludedService = v),
          activeColor: const Color(0xFF00AA55),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEquipmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Equipment Info'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedEquipmentType,
          decoration: _inputDecoration('Category'),
          items: _equipmentCategories.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedEquipmentType = v),
        ),
        const SizedBox(height: 16),
         _buildTextField('Owner Name / Business', _nameController, 'Your Name'),
        const SizedBox(height: 16),
        _buildTextField('Brand & Model', _brandModelController, 'e.g. John Deere 5310'),
        const SizedBox(height: 16),
        _buildTextField('Year of Manufacture (Optional)', _yearController, 'e.g. 2021', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField('Rental Price', _priceController, 'e.g. ₹500 / hour'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _condition,
          decoration: _inputDecoration('Condition'),
          items: _conditions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _condition = v!),
        ),

        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Operator Available?'),
          subtitle: const Text('Can you provide a driver/operator?'),
          value: _operatorAvailable,
          onChanged: (v) => setState(() => _operatorAvailable = v),
          activeColor: const Color(0xFF00AA55),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00AA55)),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
