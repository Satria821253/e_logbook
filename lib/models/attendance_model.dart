class AttendanceModel {
  final String id;
  final String crewName;
  final String vesselName;
  final DateTime tripDate;
  final String status; // 'hadir', 'izin', 'tidak_hadir'
  final String? reason; // alasan jika izin/tidak hadir
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.crewName,
    required this.vesselName,
    required this.tripDate,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      crewName: json['crew_name'],
      vesselName: json['vessel_name'],
      tripDate: DateTime.parse(json['trip_date']),
      status: json['status'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crew_name': crewName,
      'vessel_name': vesselName,
      'trip_date': tripDate.toIso8601String(),
      'status': status,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}