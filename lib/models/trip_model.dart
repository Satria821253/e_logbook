class TripModel {
  final int id;
  final String taskTitle;
  final KapalInfo kapal;
  final NahkodaInfo nahkoda;
  final DateTime tanggalBerangkat;
  final DateTime estimasiPulang;
  final int durasi;
  final String status;
  final AreaTangkap areaTangkap;
  final String targetIkan;
  final double estimasiBerat;
  final String? suratTugas;
  final List<int> awakKapal;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.taskTitle,
    required this.kapal,
    required this.nahkoda,
    required this.tanggalBerangkat,
    required this.estimasiPulang,
    required this.durasi,
    required this.status,
    required this.areaTangkap,
    required this.targetIkan,
    required this.estimasiBerat,
    this.suratTugas,
    required this.awakKapal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    // Parse awakKapal - bisa array of int atau array of object
    List<int> parseAwakKapal(dynamic awakKapal) {
      if (awakKapal == null) return [];
      if (awakKapal is List) {
        return awakKapal.map((item) {
          if (item is int) return item;
          if (item is Map) return item['id'] as int? ?? 0;
          return 0;
        }).where((id) => id != 0).toList();
      }
      return [];
    }
    
    return TripModel(
      id: json['id'],
      taskTitle: json['taskTitle'] ?? 'Trip ${json['kapal']?['namaKapal'] ?? ''}',
      kapal: KapalInfo.fromJson(json['kapal']),
      nahkoda: json['nahkoda'] != null 
          ? NahkodaInfo.fromJson(json['nahkoda'])
          : NahkodaInfo(id: 0, nama: '-', username: '-'),
      tanggalBerangkat: DateTime.parse(json['tanggalBerangkat']),
      estimasiPulang: DateTime.parse(json['estimasiPulang']),
      durasi: json['durasi'] ?? 0,
      status: json['status'],
      areaTangkap: json['areaTangkap'] != null 
          ? AreaTangkap.fromJson(json['areaTangkap'])
          : AreaTangkap(nama: '-'),
      targetIkan: json['targetIkan'] ?? '-',
      estimasiBerat: (json['estimasiBerat'] ?? 0).toDouble(),
      suratTugas: json['suratTugas'],
      awakKapal: parseAwakKapal(json['awakKapal']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

class KapalInfo {
  final int id;
  final String namaKapal;
  final String nomorRegistrasi;
  final String tipeKapal;

  KapalInfo({
    required this.id,
    required this.namaKapal,
    required this.nomorRegistrasi,
    required this.tipeKapal,
  });

  factory KapalInfo.fromJson(Map<String, dynamic> json) {
    return KapalInfo(
      id: json['id'],
      namaKapal: json['namaKapal'] ?? json['nama'] ?? '-',
      nomorRegistrasi: json['nomorRegistrasi'] ?? '-',
      tipeKapal: json['tipeKapal'] ?? 'penangkap_ikan',
    );
  }
}

class NahkodaInfo {
  final int id;
  final String nama;
  final String username;

  NahkodaInfo({
    required this.id,
    required this.nama,
    required this.username,
  });

  factory NahkodaInfo.fromJson(Map<String, dynamic> json) {
    return NahkodaInfo(
      id: json['id'],
      nama: json['nama'],
      username: json['username'],
    );
  }
}

class AreaTangkap {
  final String nama;

  AreaTangkap({required this.nama});

  factory AreaTangkap.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AreaTangkap(nama: '-');
    return AreaTangkap(nama: json['nama'] ?? '-');
  }
}
