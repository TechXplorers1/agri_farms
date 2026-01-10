import 'package:flutter/material.dart';
import '../../utils/calculator_utils.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  const FertilizerCalculatorScreen({super.key});

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen> {
  String _selectedCrop = 'Wheat';
  final TextEditingController _areaController = TextEditingController();
  Map<String, double>? _results;

  final List<String> _crops = ['Wheat', 'Rice', 'Cotton', 'Sugarcane', 'Maize'];

  void _calculate() {
    if (_areaController.text.isEmpty) return;
    
    double area = double.tryParse(_areaController.text) ?? 0;
    if (area <= 0) return;

    setState(() {
      _results = CalculatorUtils.calculateFertilizer(_selectedCrop, area);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fertilizer Calculator'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(height: 30),
            if (_results != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Crop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCrop,
                isExpanded: true,
                items: _crops.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCrop = newValue!;
                    _results = null; // Reset results on change
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Field Area (Acres)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _areaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter area in acres',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AA55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Calculate', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    // Convert kg to bags (approx 50kg per bag usually)
    int ureaBags = (_results!['Urea']! / 45).ceil(); // 45kg bags commonly for Urea now
    int dapBags = (_results!['DAP']! / 50).ceil();
    int mopBags = (_results!['MOP']! / 50).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended Dosage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildResultCard('Urea', '$ureaBags Bags', '${_results!['Urea']!.toStringAsFixed(1)} kg', Colors.blue[50]!, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildResultCard('DAP', '$dapBags Bags', '${_results!['DAP']!.toStringAsFixed(1)} kg', Colors.orange[50]!, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             Expanded(child: _buildResultCard('MOP/Potash', '$mopBags Bags', '${_results!['MOP']!.toStringAsFixed(1)} kg', Colors.red[50]!, Colors.red)),
             const SizedBox(width: 12),
             const Expanded(child: SizedBox()), // Placeholder to keep grid alignment
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Note: These are estimates based on standard $_selectedCrop requirements. Soil test based recommendation is always best.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String name, String mainValue, String subValue, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(mainValue, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(subValue, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
