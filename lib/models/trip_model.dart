enum TripStatus { ongoing, completed }

class TripModel {
  final String id;
  final String vesselName;
  final String vesselNumber;
  final String captainName;
  final int crewCount;
  final String harborName;

  final DateTime departureTime;
  final DateTime? arrivalTime;
  final int estimatedDurationDays;

  final double initialFuel;
  final double remainingFuel;
  final double fuelConsumed;

  final bool zoneViolation;
  final TripStatus status;
  final bool hasCatch;

  TripModel({
    required this.id,
    required this.vesselName,
    required this.vesselNumber,
    required this.captainName,
    required this.crewCount,
    required this.harborName,
    required this.departureTime,
    this.arrivalTime,
    required this.estimatedDurationDays,
    required this.initialFuel,
    required this.remainingFuel,
    required this.fuelConsumed,
    required this.zoneViolation,
    required this.status,
    required this.hasCatch,
  });

  TripModel copyWith({
    DateTime? arrivalTime,
    double? remainingFuel,
    double? fuelConsumed,
    TripStatus? status,
    bool? hasCatch,
  }) {
    return TripModel(
      id: id,
      vesselName: vesselName,
      vesselNumber: vesselNumber,
      captainName: captainName,
      crewCount: crewCount,
      harborName: harborName,
      departureTime: departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      estimatedDurationDays: estimatedDurationDays,
      initialFuel: initialFuel,
      remainingFuel: remainingFuel ?? this.remainingFuel,
      fuelConsumed: fuelConsumed ?? this.fuelConsumed,
      zoneViolation: zoneViolation,
      status: status ?? this.status,
      hasCatch: hasCatch ?? this.hasCatch,
    );
  }
}
