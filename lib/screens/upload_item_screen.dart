import 'package:flutter/material.dart';
import '../utils/provider_manager.dart';

class UploadItemScreen extends StatefulWidget {
  final String category; // 'Transport' or 'Equipment'

  const UploadItemScreen({super.key, required this.category});

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  String? _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Farm Worker specific controllers
  final TextEditingController _maleCountController = TextEditingController();
  final TextEditingController _femaleCountController = TextEditingController();
  final TextEditingController _malePriceController = TextEditingController();
  final TextEditingController _femalePriceController = TextEditingController();

  // Mock lists
  final List<String> _equipmentTypes = ['Tractor', 'Harvester', 'Sprayer', 'Trolley', 'Other'];
  final List<String> _transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _maleCountController.dispose();
    _femaleCountController.dispose();
    _malePriceController.dispose();
    _femalePriceController.dispose();
    super.dispose();
  }

  void _submit() {
    bool isFarmWorker = widget.category == 'Farm Workers';
    bool isValid = isFarmWorker
        ? _nameController.text.isNotEmpty && 
          (_maleCountController.text.isNotEmpty || _femaleCountController.text.isNotEmpty) &&
          (_malePriceController.text.isNotEmpty || _femalePriceController.text.isNotEmpty)
        : _selectedType != null && _nameController.text.isNotEmpty && _priceController.text.isNotEmpty;

    if (isValid) {
      if (isFarmWorker) {
        ProviderManager().addProvider(ServiceProvider(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          serviceName: 'Farm Workers',
          maleCount: int.tryParse(_maleCountController.text),
          femaleCount: int.tryParse(_femaleCountController.text),
          malePrice: int.tryParse(_malePriceController.text),
          femalePrice: int.tryParse(_femalePriceController.text),
          distance: '0.5 km', // Mock distance
          rating: 5.0, // New listing
        ));
      }
      
      // Mock submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item uploaded successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> itemTypes = widget.category == 'Equipment' ? _equipmentTypes : _transportTypes;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Upload ${widget.category}'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Placeholder (Only for non-Farm Workers)
            if (widget.category != 'Farm Workers') ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Picture',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],


            const SizedBox(height: 24),

            // Condition for Item Type vs Worker Details
            if (widget.category != 'Farm Workers') ...[
              Text(
                'Select Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: itemTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ChoiceChip(
                        label: Text(
                          type,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00AA55),
                        backgroundColor: Colors.white,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('Item Name / Title', _nameController, 'e.g., Mahindra Tractor 575'),
               const SizedBox(height: 16),
               _buildTextField(
                  widget.category == 'Transport' ? 'Capacity (Tons/Kg)' : 'Specifications',
                  _capacityController,
                  widget.category == 'Transport' ? 'e.g., 2 Tons' : 'e.g., 45 HP'),
               const SizedBox(height: 16),
               _buildTextField('Rental Price', _priceController, 'e.g., ₹500/hour', keyboardType: TextInputType.number),
               const SizedBox(height: 16),
            ] else ...[
               // Farm Worker Specific Fields
               Text(
                'Worker Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
               _buildTextField('Provider Name / Group Name', _nameController, 'e.g., Ramesh Labour Group'),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(child: _buildTextField('Male Workers', _maleCountController, 'Count', keyboardType: TextInputType.number)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildTextField('Female Workers', _femaleCountController, 'Count', keyboardType: TextInputType.number)),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(child: _buildTextField('Price/Male (₹)', _malePriceController, 'e.g. 500', keyboardType: TextInputType.number)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildTextField('Price/Female (₹)', _femalePriceController, 'e.g. 700', keyboardType: TextInputType.number)),
                 ],
               ),
               const SizedBox(height: 16),
            ],

            _buildTextField('Description (Optional)', _descriptionController, 'Additional details...', maxLines: 3),

            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Upload Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
