import 'package:flutter/material.dart';

class CropAdvisoryScreen extends StatelessWidget {
  const CropAdvisoryScreen({super.key});

  static final List<Map<String, dynamic>> crops = [
    {
      'name': 'Wheat',
      'icon': Icons.grass,
      'color': Colors.amber,
      'details': {
        'Overview': 'Wheat is a major Rabi crop, best grown in cool winters.',
        'Sowing': 'Nov 1 - Nov 30\n\nSeed Rate: 40-50 kg/acre\nSpacing: 20-22.5 cm rows',
        'Fertilizer': 'Nitrogen: 50kg/acre (Split 3 times)\nPhosphorus: 25kg/acre (Basal)\nPotash: 20kg/acre (Basal)',
        'Protection': 'Termites: Chlorpyriphos 20 EC @ 1L/acre\nRust: Propiconazole @ 200ml/acre',
        'Harvest': 'When grain is hard and moisture is < 20%.\nTypical months: April-May',
      }
    },
    {
      'name': 'Rice (Paddy)',
      'icon': Icons.water_drop,
      'color': Colors.green,
      'details': {
        'Overview': 'Primary Kharif crop, requires high water availability.',
        'Sowing': 'Nursery: May-June\nTransplanting: June-July\nSeed Rate: 10-12 kg/acre (Transplanted)',
        'Fertilizer': 'Nitrogen: 40kg/acre\nPhosphorus: 20kg/acre\nZinc Sulphate: 10kg/acre',
        'Protection': 'Stem Borer: Cartap Hydrochloride\nBlast: Tricyclazole',
        'Harvest': 'When 80% panicles turn golden yellow.\nTypical months: Oct-Nov',
      }
    },
    {
      'name': 'Cotton',
      'icon': Icons.cloud,
      'color': Colors.grey,
      'details': {
        'Overview': 'Cash crop, requires warm climate and deep black soil.',
        'Sowing': 'Warning: Prevent Pink Bollworm\nMay 15 - June 15\nSeed Rate: 2 packets/acre (Bt)',
        'Fertilizer': 'High N requirement.\nN: 60kg, P: 30kg, K: 20kg per acre.',
        'Protection': 'Sucking pests: Imidacloprid\nBollworms: Integrated Pest Management',
        'Harvest': 'Pick clean, dry bolls in morning hours.\nUsually 3-4 pickings.',
      }
    },
    {
      'name': 'Sugarcane',
      'icon': Icons.forest,
      'color': Colors.green[800],
      'details': {
        'Overview': 'Long duration crop (10-12 months). Heavy feeder.',
        'Sowing': 'Spring: Feb-March\nAutumn: Sept-Oct\nSeed: 3 bud setts @ 15,000/acre',
        'Fertilizer': 'Nitrogen: 100kg/acre\nPhosphorus: 40kg/acre\nApply N in 4 splits.',
        'Protection': 'Borer: Chlorantraniliprole\nRed Rot: Treat setts with Carbendazim',
        'Harvest': 'When brix reading is > 18%.\nCut close to ground level.',
      }
    },
     {
      'name': 'Maize',
      'icon': Icons.grain,
      'color': Colors.orange,
      'details': {
        'Overview': 'Versatile crop, grown in Kharif, Rabi and Spring.',
        'Sowing': 'Kharif: June-July\nSeed Rate: 8-10 kg/acre\nSpacing: 60x20 cm',
        'Fertilizer': 'N: 50kg, P: 25kg, K: 20kg per acre.\nApply Zinc if needed.',
        'Protection': 'Fall Armyworm: Emamectin Benzoate',
        'Harvest': 'Cobs turn dry and pale brown.',
      }
    },
    {
      'name': 'Tomato',
      'icon': Icons.circle,
      'color': Colors.red,
      'details': {
        'Overview': 'Popular vegetable crop.',
        'Sowing': 'Nursery raising required.\nTransplant after 25 days.\nSpacing: 60x45 cm',
        'Fertilizer': 'FYM: 10 tons/acre\nN:P:K 40:24:24 kg/acre',
        'Protection': 'Leaf Curl: Control Whitefly with Acetamiprid\nBlight: Mancozeb',
        'Harvest': 'Pick at breaker stage for distant market.',
      }
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light bg
      appBar: AppBar(
        title: const Text('Crop Advisory'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Slightly taller cards
        ),
        itemCount: crops.length,
        itemBuilder: (context, index) {
          final crop = crops[index];
          return _buildCropCard(context, crop);
        },
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, Map<String, dynamic> crop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CropDetailScreen(crop: crop)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (crop['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(crop['icon'], size: 40, color: crop['color']),
            ),
            const SizedBox(height: 12),
            Text(
              crop['name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 4),
            const Text(
              'Click for details',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class CropDetailScreen extends StatelessWidget {
  final Map<String, dynamic> crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> details = crop['details'];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(crop['name']),
         backgroundColor: Colors.white,
         surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
               child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (crop['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(crop['icon'], size: 60, color: crop['color']),
              ),
             ),
             const SizedBox(height: 24),
             _buildSection('Overview', details['Overview']!, Icons.info_outline, Colors.blue),
             _buildSection('Sowing', details['Sowing']!, Icons.calendar_month, Colors.green),
             _buildSection('Fertilizer', details['Fertilizer']!, Icons.science, Colors.orange),
             _buildSection('Plant Protection', details['Protection']!, Icons.bug_report, Colors.red),
             _buildSection('Harvesting', details['Harvest']!, Icons.agriculture, Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
