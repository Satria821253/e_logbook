
import 'package:e_logbook/models/harbor_zone.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IndonesiaHarbors {
  /// Data 24 Pelabuhan Perikanan Utama di Indonesia
  static final List<HarborZone> allHarbors = [
    // SUMATERA (6 Pelabuhan)
    HarborZone(
      id: 'PPN-001',
      name: 'PPN Sibolga',
      province: 'Sumatera Utara',
      centerPoint: const LatLng(1.7397, 98.7783),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan utama di pantai barat Sumatera',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Udang'],
    ),
    HarborZone(
      id: 'PPS-002',
      name: 'PPS Belawan',
      province: 'Sumatera Utara',
      centerPoint: const LatLng(3.7822, 98.6833),
      radiusKm: 60,
      harborType: 'Perikanan Samudra',
      description: 'Pelabuhan perikanan samudra terbesar di Sumatera Utara',
      allowedFishTypes: ['Tuna', 'Kakap', 'Kerapu', 'Udang', 'Cumi-cumi'],
    ),
    HarborZone(
      id: 'PPN-003',
      name: 'PPN Pekanbaru',
      province: 'Riau',
      centerPoint: const LatLng(0.5071, 101.4478),
      radiusKm: 40,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan di perairan Riau',
      allowedFishTypes: ['Bawal', 'Tenggiri', 'Kakap', 'Udang'],
    ),
    HarborZone(
      id: 'PPN-004',
      name: 'PPN Sungailiat',
      province: 'Bangka Belitung',
      centerPoint: const LatLng(-1.8553, 106.1169),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Bangka Belitung',
      allowedFishTypes: ['Kakap', 'Kerapu', 'Udang', 'Cumi-cumi'],
    ),
    HarborZone(
      id: 'PPS-005',
      name: 'PPS Bungus',
      province: 'Sumatera Barat',
      centerPoint: const LatLng(-1.0506, 100.4100),
      radiusKm: 55,
      harborType: 'Perikanan Samudra',
      description: 'Pelabuhan perikanan samudra Padang',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Tenggiri'],
    ),
    HarborZone(
      id: 'PPN-006',
      name: 'PPN Lampulo',
      province: 'Aceh',
      centerPoint: const LatLng(5.5577, 95.3222),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Banda Aceh',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Udang'],
    ),

    // JAWA (7 Pelabuhan)
    HarborZone(
      id: 'PPS-007',
      name: 'PPS Nizam Zachman',
      province: 'DKI Jakarta',
      centerPoint: const LatLng(-6.1083, 106.8850),
      radiusKm: 70,
      harborType: 'Perikanan Samudra',
      description: 'Pelabuhan perikanan terbesar di Indonesia',
      allowedFishTypes: ['Tuna', 'Kakap', 'Kerapu', 'Udang', 'Cumi-cumi'],
    ),
    HarborZone(
      id: 'PPN-008',
      name: 'PPN Palabuhanratu',
      province: 'Jawa Barat',
      centerPoint: const LatLng(-6.9870, 106.5456),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan pantai selatan Jawa Barat',
      allowedFishTypes: ['Tuna', 'Tongkol', 'Cakalang', 'Lemuru'],
    ),
    HarborZone(
      id: 'PPS-009',
      name: 'PPS Cilacap',
      province: 'Jawa Tengah',
      centerPoint: const LatLng(-7.7326, 109.0070),
      radiusKm: 55,
      harborType: 'Perikanan Samudra',
      description: 'Pelabuhan perikanan samudra Cilacap',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Layur'],
    ),
    HarborZone(
      id: 'PPN-010',
      name: 'PPN Pekalongan',
      province: 'Jawa Tengah',
      centerPoint: const LatLng(-6.8886, 109.6753),
      radiusKm: 40,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Pekalongan',
      allowedFishTypes: ['Udang', 'Rajungan', 'Cumi-cumi', 'Ikan Demersal'],
    ),
    HarborZone(
      id: 'PPN-011',
      name: 'PPN Brondong',
      province: 'Jawa Timur',
      centerPoint: const LatLng(-6.8900, 112.2620),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Lamongan',
      allowedFishTypes: ['Lemuru', 'Tongkol', 'Layang', 'Kembung'],
    ),
    HarborZone(
      id: 'PPN-012',
      name: 'PPN Prigi',
      province: 'Jawa Timur',
      centerPoint: const LatLng(-8.3300, 111.7200),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Trenggalek',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Lemuru'],
    ),
    HarborZone(
      id: 'PPN-013',
      name: 'PPN Pengambengan',
      province: 'Bali',
      centerPoint: const LatLng(-8.3900, 114.7400),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Jembrana, Bali',
      allowedFishTypes: ['Tuna', 'Lemuru', 'Tongkol', 'Cakalang'],
    ),

    // KALIMANTAN (3 Pelabuhan)
    HarborZone(
      id: 'PPN-014',
      name: 'PPN Pontianak',
      province: 'Kalimantan Barat',
      centerPoint: const LatLng(-0.0263, 109.3425),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Pontianak',
      allowedFishTypes: ['Kakap', 'Kerapu', 'Udang', 'Bawal'],
    ),
    HarborZone(
      id: 'PPN-015',
      name: 'PPN Tarakan',
      province: 'Kalimantan Utara',
      centerPoint: const LatLng(3.3000, 117.6333),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Tarakan',
      allowedFishTypes: ['Tuna', 'Kakap', 'Kerapu', 'Udang'],
    ),
    HarborZone(
      id: 'PPN-016',
      name: 'PPN Amamapare',
      province: 'Kalimantan Timur',
      centerPoint: const LatLng(-0.8667, 116.5833),
      radiusKm: 40,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Balikpapan',
      allowedFishTypes: ['Kakap', 'Kerapu', 'Udang', 'Cumi-cumi'],
    ),

    // SULAWESI (4 Pelabuhan)
    HarborZone(
      id: 'PPS-017',
      name: 'PPS Bitung',
      province: 'Sulawesi Utara',
      centerPoint: const LatLng(1.4480, 125.1880),
      radiusKm: 65,
      harborType: 'Perikanan Samudra',
      description: 'Pelabuhan perikanan samudra terbesar di Indonesia Timur',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Skipjack'],
    ),
    HarborZone(
      id: 'PPN-018',
      name: 'PPN Kwandang',
      province: 'Gorontalo',
      centerPoint: const LatLng(0.8167, 122.8833),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Gorontalo',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Layang'],
    ),
    HarborZone(
      id: 'PPN-019',
      name: 'PPN Kendari',
      province: 'Sulawesi Tenggara',
      centerPoint: const LatLng(-3.9778, 122.5950),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Kendari',
      allowedFishTypes: ['Tuna', 'Kakap', 'Kerapu', 'Udang'],
    ),
    HarborZone(
      id: 'PPN-020',
      name: 'PPN Paotere',
      province: 'Sulawesi Selatan',
      centerPoint: const LatLng(-5.1244, 119.4058),
      radiusKm: 45,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Makassar',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Kerapu'],
    ),

    // MALUKU & PAPUA (4 Pelabuhan)
    HarborZone(
      id: 'PPN-021',
      name: 'PPN Tual',
      province: 'Maluku',
      centerPoint: const LatLng(-5.6167, 132.7333),
      radiusKm: 55,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Kepulauan Kei',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Skipjack'],
    ),
    HarborZone(
      id: 'PPN-022',
      name: 'PPN Ternate',
      province: 'Maluku Utara',
      centerPoint: const LatLng(0.7833, 127.3667),
      radiusKm: 50,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Ternate',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Kerapu'],
    ),
    HarborZone(
      id: 'PPN-023',
      name: 'PPN Sorong',
      province: 'Papua Barat',
      centerPoint: const LatLng(-0.8667, 131.2500),
      radiusKm: 60,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Papua Barat',
      allowedFishTypes: ['Tuna', 'Cakalang', 'Tongkol', 'Skipjack'],
    ),
    HarborZone(
      id: 'PPN-024',
      name: 'PPN Merauke',
      province: 'Papua',
      centerPoint: const LatLng(-8.4833, 140.4000),
      radiusKm: 55,
      harborType: 'Perikanan Nusantara',
      description: 'Pelabuhan perikanan Papua selatan',
      allowedFishTypes: ['Tuna', 'Kakap', 'Kerapu', 'Udang'],
    ),
  ];

  /// Dapatkan daftar nama pelabuhan untuk dropdown
  static List<String> get harborNames {
    return allHarbors.map((h) => h.fullName).toList();
  }

  /// Cari pelabuhan berdasarkan nama lengkap
  static HarborZone? getHarborByFullName(String fullName) {
    try {
      return allHarbors.firstWhere((h) => h.fullName == fullName);
    } catch (e) {
      return null;
    }
  }

  /// Cari pelabuhan berdasarkan ID
  static HarborZone? getHarborById(String id) {
    try {
      return allHarbors.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Cari pelabuhan terdekat dari koordinat
  static HarborZone? findNearestHarbor(double lat, double lng) {
    if (allHarbors.isEmpty) return null;

    HarborZone nearest = allHarbors[0];
    double minDistance = nearest.getDistanceFromCenter(lat, lng);

    for (var harbor in allHarbors.skip(1)) {
      double distance = harbor.getDistanceFromCenter(lat, lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = harbor;
      }
    }

    return nearest;
  }

  /// Cek apakah lokasi dalam zona pelabuhan mana pun
  static Map<String, dynamic> checkLocationInAnyZone(double lat, double lng) {
    for (var harbor in allHarbors) {
      if (harbor.isLocationInZone(lat, lng)) {
        return {
          'isInZone': true,
          'harbor': harbor,
          'distance': harbor.getDistanceFromCenter(lat, lng),
        };
      }
    }

    // Jika tidak dalam zona, cari yang terdekat
    final nearest = findNearestHarbor(lat, lng);
    return {
      'isInZone': false,
      'nearestHarbor': nearest,
      'distance': nearest?.getDistanceFromCenter(lat, lng),
    };
  }

  /// Filter pelabuhan berdasarkan provinsi
  static List<HarborZone> getHarborsByProvince(String province) {
    return allHarbors.where((h) => h.province == province).toList();
  }

  /// Dapatkan daftar provinsi yang memiliki pelabuhan
  static List<String> get provinces {
    return allHarbors.map((h) => h.province).toSet().toList()..sort();
  }
}