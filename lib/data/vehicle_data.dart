class VehicleData {
  // Category -> Make -> List of Models
  static final Map<String, Map<String, List<String>>> data = {
    'Tractors': {
      'Mahindra': [
        '575 DI',
        '275 DI TU',
        '475 DI',
        'Yuvo 575 DI',
        'Jivo 245 DI',
        'Arjun Novo 605 Di-i',
        'XP Plus 265 DI',
        'Oja 3140',
        '585 DI XP Plus',
        'Other'
      ],
      'Swaraj': [
        '744 FE',
        '855 FE',
        '735 FE',
        '717',
        '963 FE',
        '724 XM',
        '742 XT',
        '843 XM',
        'Other'
      ],
      'John Deere': [
        '5310',
        '5050 D',
        '5105',
        '5405',
        '3028 EN',
        '5045 D',
        '5075 E',
        '5210',
        'Other'
      ],
      'Sonalika': [
        'DI 745 III',
        'DI 35',
        'DI 60',
        'DI 750 III',
        'Tiger 55',
        'GT 20',
        'Sikander DI 35',
        'Other'
      ],
      'Escorts Powertrac': [
        'Euro 50',
        '439 DS Plus',
        '434 DS',
        'Euro 60',
        'ALT 4000',
        'Other'
      ],
      'Farmtrac': [
        '60 Powermaxx',
        '45',
        '6055 Powermaxx',
        'Champion 35',
        'Atom 26',
        'Other'
      ],
      'New Holland': [
        '3630 TX Special Edition',
        '3230 TX',
        '3600-2 TX',
        '4710',
        '5620 TX Plus',
        'Other'
      ],
      'Eicher': [
        '380',
        '242',
        '551',
        '333',
        '485',
        '557',
        '188',
        'Other'
      ],
      'Kubota': [
        'MU4501 2WD',
        'L4508',
        'A211N',
        'NeoStar B2741',
        'MU5501',
        'Other'
      ],
      'Other': []
    },
    'Harvesters': {
      'Preet': ['987', '949', '749', 'Other'],
      'Claas': ['Crop Tiger 30', 'Crop Tiger 40', 'Dominator 40', 'Other'],
      'Dasmesh': ['9100', '7100', '3100', 'Other'],
      'Kartar': ['4000', '3500', 'Other'],
      'Malkit': ['897', '997', 'Other'],
      'Swaraj': ['8100', 'Pro Combine 7060', 'Other'],
      'John Deere': ['W50', 'W70', 'Other'],
      'Mahindra': ['HarvestMaster H12 4WD', 'Other'],
      'Other': []
    },
    'Mini Truck': {
      'Tata Motors': [
        'Ace Gold',
        'Ace Mega',
        'Intra V10',
        'Intra V30',
        'Yodha',
        'Xenon',
        'Other'
      ],
      'Mahindra': [
        'Jeeto',
        'Supro Maxitruck',
        'Bolero Pik-Up',
        'Bolero Maxitruck',
        'Supro Minitruck',
        'Other'
      ],
      'Ashok Leyland': ['Dost+', 'Bada Dost', 'Dost Strong', 'Dost LiTE', 'Other'],
      'Maruti Suzuki': ['Super Carry', 'Eeco Cargo', 'Other'],
      'Other': []
    },
    'Trolleys': {
       'Standard': ['Hydraulic Tipping', 'Non-Tipping', '2 Wheel', '4 Wheel'],
       'Other': []
    },
    'Rotavators': {
        'Shaktiman': ['Regular', 'Semi Champion', 'Champion', 'Other'],
        'Sonalika': ['Challenger', 'Smart', 'Other'],
        'Mahindra': ['Gyrovator ZLX', 'Gyrovator SLX', 'Other'],
        'Other': []
    },
    'Tractor Trolley': {
      'Mahindra': ['Trolley', 'Other'],
      'Swaraj': ['Trolley', 'Other'],
      'Local': ['2 Wheel', '4 Wheel', 'Other'],
      'Other': []
    },
    'Full Truck': {
      'Tata Motors': ['LPT 1918', 'Signa 2823.K', 'Prima 2825.K', 'LPT 4225', 'Other'],
      'Ashok Leyland': ['Ecomet 1615', 'Boss 1920', 'Captain 2823', 'U-Truck 2518', 'Other'],
      'Eicher': ['Pro 3019', 'Pro 6028', 'Pro 2049', 'Other'],
      'Mahindra': ['Blazo X 28', 'Furio 17', 'Other'],
      'BharatBenz': ['1923C', '2823C', '3528C', 'Other'],
      'Other': []
    },
    'Tempo': {
      'Force Motors': ['Traveller', 'Trax Cruiser', 'Other'],
      'Bajaj': ['Maxima C', 'RE', 'Other'],
      'Piaggio': ['Ape Xtra LDX', 'Porter 700', 'Other'],
      'Mahindra': ['Alfa Plus', 'Supro', 'Other'],
      'Other': []
    },
    'Pickup Van': {
      'Mahindra': ['Bolero Pik-Up', 'Bolero Camper', 'Bolero Maxitruck', 'Other'],
      'Tata Motors': ['Yodha', 'Xenon', 'Ace', 'Other'],
      'Isuzu': ['D-Max', 'S-Cab', 'Other'],
      'Toyota': ['Hilux', 'Other'],
       'Ashok Leyland': ['Dost+', 'Bada Dost', 'Other'],
       'Other': []
    },
    'Container': {
      'Tata Motors': ['LPT 1918 Container', 'Prima 4025.S', 'Other'],
      'Ashok Leyland': ['Ecomet 1615 Container', 'Boss 1415', 'Other'],
      'Eicher': ['Pro 3015 Container', 'Other'],
      'Other': []
    }
  };

  static List<String> getMakes(String category) {
    if (data.containsKey(category)) {
      var makes = data[category]!.keys.toList();
      // Ensure 'Other' is at the end if it exists
      if (makes.contains('Other')) {
        makes.remove('Other');
        makes.add('Other');
      }
      return makes;
    }
    return ['Other'];
  }

  static List<String> getModels(String category, String make) {
    if (data.containsKey(category) && data[category]!.containsKey(make)) {
      var models = data[category]![make]!;
       if (models.contains('Other')) {
        // Ensure Other is last
        List<String> sortedMap = List.from(models);
        sortedMap.remove('Other');
        sortedMap.add('Other');
        return sortedMap;
      }
      return models;
    }
    return [];
  }
}
