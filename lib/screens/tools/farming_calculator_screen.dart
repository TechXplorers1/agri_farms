import 'package:flutter/material.dart';
import '../../utils/calculator_utils.dart';

class FarmingCalculatorScreen extends StatefulWidget {
  const FarmingCalculatorScreen({super.key});

  @override
  State<FarmingCalculatorScreen> createState() => _FarmingCalculatorScreenState();
}

class _FarmingCalculatorScreenState extends State<FarmingCalculatorScreen> {
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _yieldController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  Map<String, double>? _results;

  void _calculate() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final yieldVal = double.tryParse(_yieldController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (cost > 0 && yieldVal > 0 && price > 0) {
      setState(() {
        _results = CalculatorUtils.calculateROI(
          totalCost: cost,
          yieldCount: yieldVal,
          pricePerUnit: price,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Farming Profit & ROI'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
        color: const Color(0xFFFFFDE7), // Light yellow bg for money/profit feel
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow[600]!, width: 0.5),
      ),
      child: Column(
        children: [
          _buildTextField('Total Cultivation Cost (₹)', _costController, 'Seeds, Labor, Water etc.'),
          const SizedBox(height: 16),
          _buildTextField('Total Yield (Quintals)', _yieldController, 'Expected harvest qty'),
          const SizedBox(height: 16),
          _buildTextField('Market Price (₹ per Quintal)', _priceController, 'Current mandi rate'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBC02D), // Gold/Yellow Dark
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Calculate Profit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              borderSide: BorderSide(color: Colors.yellow[700]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final profit = _results!['NetProfit']!;
    final isLoss = profit < 0;
    final color = isLoss ? Colors.red : Colors.green;

    return Column(
      children: [
        Text(
          isLoss ? 'Net Loss' : 'Net Profit',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${profit.abs().toStringAsFixed(0)}',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ROI: ${_results!['ROI']!.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildSummaryItem('Total Revenue', '₹${_results!['Revenue']!.toInt()}', Colors.black87),
             _buildSummaryItem('Total Cost', '₹${_costController.text}', Colors.red),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
