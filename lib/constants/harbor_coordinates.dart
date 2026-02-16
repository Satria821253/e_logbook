/// Koordinat pelabuhan-pelabuhan di Indonesia
final Map<String, Map<String, double>> harborCoordinates = {
  // Jawa
  'Pelabuhan Muara Baru': {'lat': -6.1075, 'lng': 106.7975},
  'Pelabuhan Muara Angke': {'lat': -6.1167, 'lng': 106.7833},
  'Pelabuhan Sunda Kelapa': {'lat': -6.1167, 'lng': 106.8167},
  'Pelabuhan Tanjung Priok': {'lat': -6.1044, 'lng': 106.8861},
  'Pelabuhan Cirebon': {'lat': -6.7063, 'lng': 108.5571},
  'Pelabuhan Tegal': {'lat': -6.8694, 'lng': 109.1400},
  'Pelabuhan Pekalongan': {'lat': -6.8833, 'lng': 109.6667},
  'Pelabuhan Semarang': {'lat': -6.9667, 'lng': 110.4167},
  'Pelabuhan Surabaya': {'lat': -7.2092, 'lng': 112.7350},
  
  // Sumatra
  'Pelabuhan Belawan': {'lat': 3.7833, 'lng': 98.6833},
  'Pelabuhan Dumai': {'lat': 1.6667, 'lng': 101.4500},
  'Pelabuhan Teluk Bayur': {'lat': -0.9833, 'lng': 100.3667},
  'Pelabuhan Panjang': {'lat': -5.4500, 'lng': 105.3167},
  'Pelabuhan Palembang': {'lat': -2.9833, 'lng': 104.7500},
  
  // Kalimantan
  'Pelabuhan Pontianak': {'lat': -0.0333, 'lng': 109.3167},
  'Pelabuhan Banjarmasin': {'lat': -3.3167, 'lng': 114.5833},
  'Pelabuhan Balikpapan': {'lat': -1.2667, 'lng': 116.8333},
  'Pelabuhan Samarinda': {'lat': -0.5000, 'lng': 117.1500},
  
  // Sulawesi
  'Pelabuhan Makassar': {'lat': -5.1167, 'lng': 119.4000},
  'Pelabuhan Manado': {'lat': 1.4833, 'lng': 124.8500},
  'Pelabuhan Kendari': {'lat': -3.9667, 'lng': 122.5833},
  'Pelabuhan Palu': {'lat': -0.9000, 'lng': 119.8667},
  
  // Maluku & Papua
  'Pelabuhan Ambon': {'lat': -3.6833, 'lng': 128.1833},
  'Pelabuhan Ternate': {'lat': 0.7833, 'lng': 127.3667},
  'Pelabuhan Jayapura': {'lat': -2.5333, 'lng': 140.7167},
  'Pelabuhan Sorong': {'lat': -0.8667, 'lng': 131.2500},
  
  // Bali & Nusa Tenggara
  'Pelabuhan Benoa': {'lat': -8.7500, 'lng': 115.2167},
  'Pelabuhan Lembar': {'lat': -8.7333, 'lng': 116.0667},
  'Pelabuhan Kupang': {'lat': -10.1667, 'lng': 123.5833},
};

/// Get koordinat pelabuhan berdasarkan nama
Map<String, double> getHarborCoordinates(String harborName) {
  // Cari exact match
  if (harborCoordinates.containsKey(harborName)) {
    return harborCoordinates[harborName]!;
  }
  
  // Cari partial match (case insensitive)
  final lowerName = harborName.toLowerCase();
  for (var entry in harborCoordinates.entries) {
    if (entry.key.toLowerCase().contains(lowerName) || 
        lowerName.contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  
  // Default: Jakarta (Muara Baru)
  return {'lat': -6.1075, 'lng': 106.7975};
}
