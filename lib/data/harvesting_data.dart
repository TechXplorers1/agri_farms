class HarvestingData {
  static const List<String> presetChips = [
    'Combine Harvester',
    'Paddy Harvester',
    'Maize Harvester',
    'Sugarcane Harvester',
    'Multi-Crop Harvester',
    'Reaper Binder',
    'Others',
  ];

  static const List<String> equipmentTypes = [
    'Combine Harvester (Paddy/Wheat)',
    'Sugarcane Harvester',
    'Maize / Corn Harvester',
    'Cotton Picker / Harvester',
    'Reaper / Binder',
    'Multi-crop Harvester',
    'Forage Harvester',
    'Groundnut Digger / Harvester',
    'Paddy Mini Combine',
    'Others'
  ];

  static List<String> getCapacities(String? equipmentType) {
    if (equipmentType == null || equipmentType.isEmpty) {
      return defaultCapacities;
    }

    final type = equipmentType.toLowerCase();

    if (type.contains('combine') || type.contains('paddy') || type.contains('wheat')) {
      return [
        'Track Type (Wet Land / Paddy)',
        'Wheel Type (Dry Land / Wheat)',
        '10 - 12 Feet Cutter Bar (75 - 90 HP)',
        '12 - 14 Feet Cutter Bar (90 - 110 HP)',
        'Mini Track Combine (40 - 55 HP)',
        'Custom / Other Specification'
      ];
    } else if (type.contains('sugarcane')) {
      return [
        'Single Row Harvester (150+ HP)',
        'Dual Row Harvester (200+ HP)',
        'Tractor Mounted Sugarcane Cutter',
        'Custom / Other Specification'
      ];
    } else if (type.contains('maize') || type.contains('corn')) {
      return [
        '2 Row Corn Picker',
        '3 Row Corn Picker',
        '4 Row Corn Harvester (Self Propelled)',
        'Custom / Other Specification'
      ];
    } else if (type.contains('reaper')) {
      return [
        'Power Tiller Reaper (3 - 5 HP)',
        'Tractor Front Mounted Reaper (4 Feet)',
        'Tractor Mounted Reaper (5 Feet)',
        'Self Propelled Reaper Binder',
        'Custom / Other Specification'
      ];
    }

    return defaultCapacities;
  }

  static const List<String> defaultCapacities = [
    'Track Type Combine (Paddy)',
    'Wheel Type Combine (Wheat/Grain)',
    'Tractor Mounted Reaper (4 - 5 Ft)',
    'Multi-crop Heavy Duty',
    'Mini Combine Harvester',
    'Custom / Other Specification'
  ];
}

class SprayerData {
  static const List<String> sprayerTypes = [
    'Handheld sprayers',
    'Diesel sprayers',
    'Machinery Sprayers',
    'Knapsack (backpack) sprayers',
    'Tractor Mounted Sprayers',
    'Battery Sprayers',
    'Drone Sprayers',
    'Others',
  ];
}
