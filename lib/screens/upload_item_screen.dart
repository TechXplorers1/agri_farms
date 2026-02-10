import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/provider_manager.dart';
import '../data/vehicle_data.dart';

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
  bool _driverIncluded = true;

  // Equipment Specific
  String? _selectedEquipmentType; 
  String? _selectedMake; // New
  String? _selectedModel; // New
  final TextEditingController _brandModelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(); // New
  bool _operatorAvailable = false;
  String _condition = 'Good';

  // Farm Worker Specific
  final TextEditingController _maleCountController = TextEditingController();
  final TextEditingController _femaleCountController = TextEditingController();
  final TextEditingController _malePriceController = TextEditingController();
  final TextEditingController _femalePriceController = TextEditingController();
  // Role Distribution
  final List<String> _roleDistributions = [];
  final TextEditingController _roleCountController = TextEditingController();
  // String? _selectedRoleTask; // Removed
  String _roleGender = 'Male';
  // Skills handled by _selectedSkills list now
  
  // Service Specific (Ploughing, etc.)
  final TextEditingController _equipmentUsedController = TextEditingController(); // e.g., "John Deere 5310"
  bool _operatorIncludedService = true;

  // Mock Lists
  final List<String> _transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
  final List<String> _equipmentCategories = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys']; 
  final List<String> _serviceCategories = ['Ploughing', 'Harvesting', 'Drone Spraying', 'Irrigation', 'Soil Testing', 'Vet Care', 'Electricians', 'Mechanics']; // For dropdown if category is generic 'Services' 
  
  final List<String> _conditions = ['New', 'Good', 'Average', 'Poor'];

  final List<String> _farmSkills = [
    'Harvesting', 'Sowing', 'Plowing', 'Fertilizer Application', 
    'Pesticide Spraying', 'Weeding', 'Irrigation', 'Pruning', 
    'Grading & Sorting', 'Loading & Unloading', 'Cattle Management', 'Others'
  ];
  final List<String> _selectedSkills = [];

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
    _roleCountController.dispose();
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
      _showError(AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    if (_roleDistributions.isEmpty) {
      _showError(AppLocalizations.of(context)!.selectSkillError); // Reuse or add new error message
      return;
    }


    // Derive skills from the added roles
    final derivedSkills = _roleDistributions
        .map((e) => e.split('-')[1].trim())
        .expand((e) => e.split(',').map((s) => s.trim()))
        .toSet()
        .toList();

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
      skills: derivedSkills.join(', '),
      roleDistribution: _roleDistributions,
      image: 'https://placehold.co/600x400?text=Workers',
    );

    ProviderManager().addProvider(newProvider);
    _completeSubmission();
  }



  void _submitEquipment() {
    if (_selectedEquipmentType == null || _brandModelController.text.isEmpty || _priceController.text.isEmpty) {
       _showError(AppLocalizations.of(context)!.fillRequiredFields);
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
      SnackBar(
        content: Text(AppLocalizations.of(context)!.listingUploaded),
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
    if (widget.category == 'Transport') return AppLocalizations.of(context)!.addVehicle;
    if (widget.category == 'Equipment') return AppLocalizations.of(context)!.addEquipment;
    if (widget.category == 'Farm Workers') return AppLocalizations.of(context)!.addGroup;
    return '${AppLocalizations.of(context)!.addListing} ${widget.category}';
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
                   Text(AppLocalizations.of(context)!.addPhotos, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (widget.category == 'Farm Workers') _buildFarmWorkerForm(),
            if (widget.category == 'Transport') _buildTransportForm(),
            if (widget.category == 'Equipment') _buildEquipmentForm(),
            if (!['Farm Workers', 'Transport', 'Equipment'].contains(widget.category)) _buildServicesForm(),

            const SizedBox(height: 24),
             _buildTextField(AppLocalizations.of(context)!.locationLabel, _locationController, 'e.g. Rampur, Nagpur'),
            const SizedBox(height: 16),
             _buildTextField(AppLocalizations.of(context)!.descriptionLabel, _descriptionController, 'Any extra info...', maxLines: 3),

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
                child: Text(AppLocalizations.of(context)!.submitListing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        _buildSectionTitle(AppLocalizations.of(context)!.groupDetails),
        const SizedBox(height: 12),
        _buildTextField('Group Name / Leader Name', _nameController, AppLocalizations.of(context)!.groupNameHint),
        const SizedBox(height: 16),
        
        // Skills selection removed as per request. Skills are now derived from Role Distribution.

        const SizedBox(height: 20),
        
        _buildSectionTitle(AppLocalizations.of(context)!.staffPricing),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(AppLocalizations.of(context)!.maleWorkers, _maleCountController, 'Count', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
             Expanded(child: _buildTextField(AppLocalizations.of(context)!.priceMale, _malePriceController, AppLocalizations.of(context)!.dailyWage, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
           children: [
            Expanded(child: _buildTextField(AppLocalizations.of(context)!.femaleWorkers, _femaleCountController, 'Count', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(AppLocalizations.of(context)!.priceFemale, _femalePriceController, AppLocalizations.of(context)!.dailyWage, keyboardType: TextInputType.number)),
          ],
        ),
        _buildRoleDistributionForm(),
      ],
    );
  }


  Widget _buildTransportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.vehicleDetails),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedTransportType,
          decoration: _inputDecoration(AppLocalizations.of(context)!.vehicleType),
          items: _transportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedTransportType = v),
        ),
        const SizedBox(height: 16),
        _buildTextField('Vehicle Name / Title', _nameController, AppLocalizations.of(context)!.vehicleNameHint),
        const SizedBox(height: 16),
        _buildTextField(AppLocalizations.of(context)!.vehicleNumber, _vehicleNumberController, 'e.g. MH 40 AB 1234'),
        const SizedBox(height: 16),
        _buildTextField(AppLocalizations.of(context)!.loadCapacity, _capacityController, 'e.g. 1.5 Ton'),
        const SizedBox(height: 16),
        _buildTextField(AppLocalizations.of(context)!.serviceArea, _serviceAreaController, 'e.g. Within 50km or specific districts'),
        
        const SizedBox(height: 20),
        _buildSectionTitle(AppLocalizations.of(context)!.pricingAvailability),
        const SizedBox(height: 12),
        _buildTextField(AppLocalizations.of(context)!.priceLabel, _priceController, 'e.g. ₹20/km or ₹1000/trip', keyboardType: TextInputType.text),
        
        const SizedBox(height: 20),
        _buildSectionTitle(AppLocalizations.of(context)!.options),
        CheckboxListTile(
          title: Text(AppLocalizations.of(context)!.driverIncluded),
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
        _buildTextField('Price / Rate', _priceController, widget.category == 'Harvesting' ? 'e.g. ₹2000 / hour' : 'e.g. ₹1200 / acre'),
        
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
    List<String> makes = [];
    if (_selectedEquipmentType != null) {
      makes = VehicleData.getMakes(_selectedEquipmentType!);
    }

    List<String> models = [];
    if (_selectedEquipmentType != null && _selectedMake != null) {
      models = VehicleData.getModels(_selectedEquipmentType!, _selectedMake!);
    }

    bool showManualMake = makes.isEmpty || _selectedMake == 'Other';
    bool showManualModel = models.isEmpty || _selectedModel == 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.equipmentInfo),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedEquipmentType,
          decoration: _inputDecoration('Category'),
          items: _equipmentCategories.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) {
            setState(() {
              _selectedEquipmentType = v;
              _selectedMake = null;
              _selectedModel = null;
              _brandModelController.clear();
            });
          },
        ),
        const SizedBox(height: 16),
         _buildTextField('Owner Name / Business', _nameController, AppLocalizations.of(context)!.ownerNameHint),
        const SizedBox(height: 16),

        // MAKE SELECTION
        if (makes.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _selectedMake,
            decoration: _inputDecoration('Select Make'),
            items: makes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedMake = v;
                _selectedModel = null;
                _brandModelController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // MODEL SELECTION
        if (models.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: _inputDecoration('Select Model'),
            items: models.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedModel = v;
                if (v != 'Other') {
                   // If not other, we set the manual controller to this value for submission logic compatibility
                   _brandModelController.text = "${_selectedMake} $v"; 
                } else {
                   _brandModelController.clear();
                }
              });
            },
          ),
           const SizedBox(height: 16),
        ],
        
        // Manual Entry Fallback
        if (showManualMake || showManualModel) 
           _buildTextField(AppLocalizations.of(context)!.brandModel, _brandModelController, 'e.g. John Deere 5310'),

        if (showManualMake || showManualModel) 
           const SizedBox(height: 16),

        _buildTextField(AppLocalizations.of(context)!.yearManufacture, _yearController, 'e.g. 2021', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField(AppLocalizations.of(context)!.rentalPrice, _priceController, 'e.g. ₹500 / hour'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _condition,
          decoration: _inputDecoration(AppLocalizations.of(context)!.condition),
          items: _conditions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _condition = v!),
        ),

        const SizedBox(height: 20),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.operatorAvailable),
          subtitle: Text(AppLocalizations.of(context)!.operatorAvailableSubtitle),
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
  // Multi-select skills
  List<String> _selectedRoleSkills = [];

  void _addRoleDistribution() {
    final count = _roleCountController.text.trim();
    if (count.isNotEmpty && _selectedRoleSkills.isNotEmpty) {
      setState(() {
        _roleDistributions.add('$count $_roleGender - ${_selectedRoleSkills.join(", ")}');
        _roleCountController.clear();
        _selectedRoleSkills = []; // Reset list
      });
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter count and select at least one skill')));
    }
  }

  Future<void> _showMultiSelectDialog() async {
    final List<String> tempSelectedSkills = List.from(_selectedRoleSkills);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Skills'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _farmSkills.map((skill) {
                    return CheckboxListTile(
                      value: tempSelectedSkills.contains(skill),
                      title: Text(skill),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF00AA55),
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            tempSelectedSkills.add(skill);
                          } else {
                            tempSelectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRoleSkills = tempSelectedSkills;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done', style: TextStyle(color: Color(0xFF00AA55))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoleDistributionForm() {
      return Column(
          children: [
                const SizedBox(height: 20),
                _buildSectionTitle('Role Distribution (Optional)'),
                const SizedBox(height: 8),
                Text('Specify who does what (e.g. 5 Men - Sowing)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 12),
                
                Row(
                children: [
                    SizedBox(
                    width: 80,
                    child: _buildTextField('Count', _roleCountController, 'Num', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                    width: 100,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                            value: _roleGender,
                            decoration: _inputDecoration('').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                            items: ['Male', 'Female'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setState(() => _roleGender = v!),
                        ),
                        ],
                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text('Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                           const SizedBox(height: 8),
                           InkWell(
                             onTap: _showMultiSelectDialog,
                             child: InputDecorator(
                               decoration: _inputDecoration('Select Tasks').copyWith(
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                               ),
                               child: Text(
                                 _selectedRoleSkills.isEmpty ? 'Select Skills' : _selectedRoleSkills.join(', '),
                                 style: TextStyle(
                                   color: _selectedRoleSkills.isEmpty ? Colors.grey[400] : Colors.black87,
                                   fontSize: 14,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ),
                        ],
                      ),
                    ),
                ],
                ),
                const SizedBox(height: 8),
                Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                    onPressed: _addRoleDistribution,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Add', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA55),
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                ),
                ),

                const SizedBox(height: 12),
                if (_roleDistributions.isNotEmpty)
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _roleDistributions.map((item) {
                        return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(Icons.circle, size: 8, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                            InkWell(
                                onTap: () {
                                setState(() {
                                    _roleDistributions.remove(item);
                                });
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                            )
                            ],
                        ),
                        );
                    }).toList(),
                    ),
                ),
          ],
      );
  }
}
