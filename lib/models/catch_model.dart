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
    // Validasi field kritis
    if (json['fish_name'] == null || json['fish_name'].toString().trim().isEmpty) {
      throw ArgumentError('Fish name is required');
    }
    
    final weight = double.tryParse(json['weight'].toString());
    if (weight == null || weight < 0 || weight > 10000) {
      throw ArgumentError('Invalid weight value: ${json['weight']}');
    }
    
    final quantity = json['quantity'] as int?;
    if (quantity == null || quantity < 0 || quantity > 100000) {
      throw ArgumentError('Invalid quantity value: ${json['quantity']}');
    }
    
    return CatchModel(
      id: json['id'],
      fishName: json['fish_name'].toString().trim(),
      fishType: json['fish_type']?.toString() ?? '',
      weight: weight,
      quantity: quantity,
      condition: json['condition']?.toString() ?? '',
      photoPath: json['photo_path']?.toString() ?? '',
      vesselName: json['vessel_name']?.toString() ?? '',
      vesselNumber: json['vessel_number']?.toString() ?? '',
      captainName: json['captain_name']?.toString() ?? '',
      crewCount: (json['crew_count'] as int?) ?? 0,
      pricePerKg: _parseAndValidateDouble(json['price_per_kg'], 'price_per_kg', 0, 1000000),
      totalRevenue: _parseAndValidateDouble(json['total_revenue'], 'total_revenue', 0, 100000000),
      departureDate: DateTime.tryParse(json['departure_date']?.toString() ?? '') ?? DateTime.now(),
      departureTime: json['departure_time']?.toString() ?? '',
      arrivalDate: DateTime.tryParse(json['arrival_date']?.toString() ?? '') ?? DateTime.now(),
      arrivalTime: json['arrival_time']?.toString() ?? '',
      tripDurationHours: (json['trip_duration_hours'] as int?) ?? 0,
      tripDurationMinutes: (json['trip_duration_minutes'] as int?) ?? 0,
      fishingZone: json['fishing_zone']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      latitude: _parseAndValidateDouble(json['latitude'], 'latitude', -90, 90),
      longitude: _parseAndValidateDouble(json['longitude'], 'longitude', -180, 180),
      waterDepth: _parseAndValidateDouble(json['water_depth'], 'water_depth', 0, 12000),
      weatherCondition: json['weather_condition']?.toString() ?? '',
      fuelCost: _parseAndValidateDouble(json['fuel_cost'], 'fuel_cost', 0, 10000000),
      operationalCost: _parseAndValidateDouble(json['operational_cost'], 'operational_cost', 0, 10000000),
      tax: _parseAndValidateDouble(json['tax'], 'tax', 0, 10000000),
      totalCost: _parseAndValidateDouble(json['total_cost'], 'total_cost', 0, 100000000),
      netProfit: _parseAndValidateDouble(json['net_profit'], 'net_profit', -100000000, 100000000),
      notes: json['notes']?.toString(),
    );
  }
  
  static double _parseAndValidateDouble(dynamic value, String fieldName, double min, double max) {
    final parsed = double.tryParse(value.toString()) ?? 0.0;
    if (parsed < min || parsed > max) {
      throw ArgumentError('Invalid $fieldName value: $value (must be between $min and $max)');
    }
    return parsed;
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