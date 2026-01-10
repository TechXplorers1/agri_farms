import 'package:flutter/material.dart';
import '../../utils/calculator_utils.dart';

class PesticideCalculatorScreen extends StatefulWidget {
  const PesticideCalculatorScreen({super.key});

  @override
  State<PesticideCalculatorScreen> createState() => _PesticideCalculatorScreenState();
}

class _PesticideCalculatorScreenState extends State<PesticideCalculatorScreen> {
  final TextEditingController _dosageController = TextEditingController(); // ml per Litre
  final TextEditingController _tankCapacityController = TextEditingController(text: '15'); // Default 15L
  final TextEditingController _areaController = TextEditingController();
  
  Map<String, double>? _results;

  void _calculate() {
    if (_dosageController.text.isEmpty || _areaController.text.isEmpty || _tankCapacityController.text.isEmpty) return;

    final dose = double.tryParse(_dosageController.text) ?? 0;
    final tank = double.tryParse(_tankCapacityController.text) ?? 0;
    final area = double.tryParse(_areaController.text) ?? 0;

    if (dose > 0 && tank > 0 && area > 0) {
      setState(() {
        _results = CalculatorUtils.calculatePesticide(
          dosagePerLitre: dose,
          tankCapacityL: tank,
          areaAcres: area,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pesticide Calculator'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
             _buildInputCard(),
             const SizedBox(height: 24),
             if (_results != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTextField('Dosage (ml per Litre)', _dosageController, 'e.g. 2 ml'),
          const SizedBox(height: 16),
          _buildTextField('Tank Capacity (Litres)', _tankCapacityController, 'e.g. 15 L'),
          const SizedBox(height: 16),
          _buildTextField('Total Area (Acres)', _areaController, 'e.g. 1.5'),
          const SizedBox(height: 24),
           SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Calculate Tanks', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultItem('Total Tanks', '${_results!['TotalTanks']!.toInt()}', Icons.local_drink),
              Container(height: 40, width: 1, color: Colors.grey[300]),
              _buildResultItem('Total Chemical', '${_results!['TotalChemicalMl']!.toInt()} ml', Icons.science),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Total Water: ${_results!['TotalWaterL']!.toInt()} Litres',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
