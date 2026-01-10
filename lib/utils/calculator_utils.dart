class CalculatorUtils {
  // Fertilizer Calculator
  // Standard NPK recommendations per acre (Approximate generic values)
  static final Map<String, Map<String, double>> cropRequirements = {
    'Wheat': {'N': 50, 'P': 25, 'K': 20}, // kg/acre
    'Rice': {'N': 40, 'P': 20, 'K': 15},
    'Cotton': {'N': 60, 'P': 30, 'K': 20},
    'Sugarcane': {'N': 100, 'P': 40, 'K': 30},
    'Maize': {'N': 50, 'P': 25, 'K': 20},
  };

  // Content percentage in fertilizers
  static const double ureaN = 0.46; // 46% Nitrogen
  static const double dapN = 0.18;  // 18% Nitrogen
  static const double dapP = 0.46;  // 46% Phosphorus
  static const double mopK = 0.60;  // 60% Potassium

  static Map<String, double> calculateFertilizer(String crop, double areaInAcres) {
    if (!cropRequirements.containsKey(crop)) return {};

    final req = cropRequirements[crop]!;
    final totalN = req['N']! * areaInAcres;
    final totalP = req['P']! * areaInAcres;
    final totalK = req['K']! * areaInAcres;

    // 1. Calculate DAP for Phosphorus (and some Nitrogen)
    // DAP contains 46% P and 18% N
    final dapNeededKg = totalP / dapN; // derived from P requirement
    final nitrogenSuppliedByDAP = dapNeededKg * dapN;

    // 2. Calculate Remaining Nitrogen for Urea
    final remainingN = totalN - nitrogenSuppliedByDAP;
    final ureaNeededKg = remainingN > 0 ? remainingN / ureaN : 0.0;

    // 3. Calculate MOP for Potassium
    final mopNeededKg = totalK / mopK;

    return {
      'Urea': ureaNeededKg,
      'DAP': dapNeededKg,
      'MOP': mopNeededKg,
    };
  }

  // Pesticide Calculator
  static Map<String, double> calculatePesticide({
    required double dosagePerLitre, 
    required double tankCapacityL, 
    required double areaAcres
  }) {
    // Assumption: Approx 150-200 Litres of water needed per acre for spraying
    const double waterPerAcre = 150.0; 
    
    final totalWaterNeeded = areaAcres * waterPerAcre;
    final totalChemicalNeededMl = totalWaterNeeded * dosagePerLitre;
    final totalTanks = totalWaterNeeded / tankCapacityL;

    return {
      'TotalChemicalMl': totalChemicalNeededMl,
      'TotalWaterL': totalWaterNeeded,
      'TotalTanks': totalTanks.ceilToDouble(), // Can't have half a tank easily, usually rounded up
    };
  }

  // ROI Calculator
  static Map<String, double> calculateROI({
    required double totalCost,
    required double yieldCount,
    required double pricePerUnit,
  }) {
    final totalRevenue = yieldCount * pricePerUnit;
    final netProfit = totalRevenue - totalCost;
    final roi = totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;

    return {
      'Revenue': totalRevenue,
      'NetProfit': netProfit,
      'ROI': roi,
    };
  }
}
