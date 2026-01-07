class CatchModel {
  final int? id;
  final String fishName;
  final String fishType;
  final double weight;
  final int quantity;
  final String condition;
  final String photoPath;
  final String vesselName;
  final String vesselNumber;
  final String captainName;
  final int crewCount;
  final double pricePerKg;
  final double totalRevenue;
  final DateTime departureDate;
  final String departureTime;
  final DateTime arrivalDate;
  final String arrivalTime;
  final int tripDurationHours;
  final int tripDurationMinutes;
  final String fishingZone;
  final String locationName;
  final double latitude;
  final double longitude;
  final double waterDepth;
  final String weatherCondition;
  final double fuelCost;
  final double operationalCost;
  final double tax;
  final double totalCost;
  final double netProfit;
  final String? notes;
  final String syncStatus; // 'synced', 'pending', 'failed'
  final DateTime? lastSyncAttempt;
  final String? syncError;

  CatchModel({
    this.id,
    required this.fishName,
    required this.fishType,
    required this.weight,
    required this.quantity,
    required this.condition,
    required this.photoPath,
    required this.vesselName,
    required this.vesselNumber,
    required this.captainName,
    required this.crewCount,
    required this.pricePerKg,
    required this.totalRevenue,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.tripDurationHours,
    required this.tripDurationMinutes,
    required this.fishingZone,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.waterDepth,
    required this.weatherCondition,
    required this.fuelCost,
    required this.operationalCost,
    required this.tax,
    required this.totalCost,
    required this.netProfit,
    this.notes,
    this.syncStatus = 'synced',
    this.lastSyncAttempt,
    this.syncError,
  });

  factory CatchModel.fromJson(Map<String, dynamic> json) {
    return CatchModel(
      id: json['id'],
      fishName: json['fish_name'] ?? '',
      fishType: json['fish_type'] ?? '',
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 0,
      condition: json['condition'] ?? '',
      photoPath: json['photo_path'] ?? '',
      vesselName: json['vessel_name'] ?? '',
      vesselNumber: json['vessel_number'] ?? '',
      captainName: json['captain_name'] ?? '',
      crewCount: json['crew_count'] ?? 0,
      pricePerKg: double.tryParse(json['price_per_kg'].toString()) ?? 0.0,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
      departureDate: DateTime.tryParse(json['departure_date']) ?? DateTime.now(),
      departureTime: json['departure_time'] ?? '',
      arrivalDate: DateTime.tryParse(json['arrival_date']) ?? DateTime.now(),
      arrivalTime: json['arrival_time'] ?? '',
      tripDurationHours: json['trip_duration_hours'] ?? 0,
      tripDurationMinutes: json['trip_duration_minutes'] ?? 0,
      fishingZone: json['fishing_zone'] ?? '',
      locationName: json['location_name'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      waterDepth: double.tryParse(json['water_depth'].toString()) ?? 0.0,
      weatherCondition: json['weather_condition'] ?? '',
      fuelCost: double.tryParse(json['fuel_cost'].toString()) ?? 0.0,
      operationalCost: double.tryParse(json['operational_cost'].toString()) ?? 0.0,
      tax: double.tryParse(json['tax'].toString()) ?? 0.0,
      totalCost: double.tryParse(json['total_cost'].toString()) ?? 0.0,
      netProfit: double.tryParse(json['net_profit'].toString()) ?? 0.0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fish_name': fishName,
      'fish_type': fishType,
      'weight': weight,
      'quantity': quantity,
      'condition': condition,
      'photo_path': photoPath,
      'vessel_name': vesselName,
      'vessel_number': vesselNumber,
      'captain_name': captainName,
      'crew_count': crewCount,
      'price_per_kg': pricePerKg,
      'total_revenue': totalRevenue,
      'departure_date': departureDate.toIso8601String(),
      'departure_time': departureTime,
      'arrival_date': arrivalDate.toIso8601String(),
      'arrival_time': arrivalTime,
      'trip_duration_hours': tripDurationHours,
      'trip_duration_minutes': tripDurationMinutes,
      'fishing_zone': fishingZone,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'water_depth': waterDepth,
      'weather_condition': weatherCondition,
      'fuel_cost': fuelCost,
      'operational_cost': operationalCost,
      'tax': tax,
      'total_cost': totalCost,
      'net_profit': netProfit,
      'fishing_gear': 'Jaring', // Default value
      'notes': notes ?? '',
    };
  }
}