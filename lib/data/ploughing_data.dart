class PloughingData {
  static const List<String> equipmentTypes = [
    'Mouldboard Plough (MB)',
    'Disc Plough',
    'Rotavator / Rotary Tiller',
    'Cultivator (Tine Plough)',
    'Disc Harrow',
    'Subsoiler',
    'Chisel Plough',
    'Ridger / Ridge Plough',
    'Duckfoot Cultivator',
    'Others'
  ];

  static List<String> getCapacities(String? equipmentType) {
    if (equipmentType == null || equipmentType.isEmpty) {
      return defaultCapacities;
    }

    final type = equipmentType.toLowerCase();

    if (type.contains('mouldboard') || type.contains('mb')) {
      return [
        '2 Bottom (35 - 45 HP)',
        '3 Bottom (45 - 55 HP)',
        '4 Bottom (55+ HP Heavy Duty)',
        'Reversible 2 Bottom',
        'Reversible 3 Bottom',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('disc plough')) {
      return [
        '2 Disc (35 - 45 HP)',
        '3 Disc (45 - 55 HP)',
        '4 Disc (55+ HP Heavy Duty)',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('rotavator') || type.contains('rotary')) {
      return [
        '36 Blades / 5 Feet (35 - 40 HP)',
        '42 Blades / 6 Feet (40 - 45 HP)',
        '48 Blades / 7 Feet (45 - 50 HP)',
        '54 Blades / 8 Feet (50 - 60 HP)',
        '60 Blades / 9 Feet (60+ HP)',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('cultivator')) {
      return [
        '7 Tyne (25 - 35 HP)',
        '9 Tyne (35 - 45 HP)',
        '11 Tyne (45 - 55 HP)',
        '13 Tyne (55+ HP Heavy Duty)',
        '15 Tyne (Extra Heavy)',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('harrow')) {
      return [
        '12 Disc (Small / 35 HP)',
        '14 Disc (Medium / 45 HP)',
        '16 Disc (Heavy Duty / 55 HP)',
        '18 Disc (Extra Heavy / 60+ HP)',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('subsoiler') || type.contains('chisel')) {
      return [
        '1 Tyne / Single Arm',
        '2 Tyne / Double Arm',
        '3 Tyne / Triple Arm (Heavy Duty)',
        'Custom / Other Capacity'
      ];
    } else if (type.contains('ridger')) {
      return [
        '2 Row Ridger',
        '3 Row Ridger',
        '4 Row Ridger',
        'Custom / Other Capacity'
      ];
    }

    return defaultCapacities;
  }

  static const List<String> defaultCapacities = [
    '2 Bottom (35 - 45 HP)',
    '3 Bottom (45 - 55 HP)',
    '9 Tyne Cultivator (35 - 45 HP)',
    '11 Tyne Cultivator (45 - 55 HP)',
    '36 Blades / 6 Feet Rotavator',
    '42 Blades / 7 Feet Rotavator',
    '48 Blades / 8 Feet Rotavator',
    '14 Disc Harrow',
    'Heavy Duty (55+ HP)',
    'Custom / Other Capacity'
  ];
}
