import 'package:flutter/foundation.dart';
import '../models/catch_model.dart';

class CatchProvider with ChangeNotifier {
  final List<CatchModel> _catches = [];

  List<CatchModel> get catches => [..._catches];

  List<CatchModel> get todayCatches {
    final now = DateTime.now();
    return _catches.where((catch_) {
      return catch_.departureDate.year == now.year &&
          catch_.departureDate.month == now.month &&
          catch_.departureDate.day == now.day;
    }).toList();
  }

  void addCatch(CatchModel catchData) {
    _catches.insert(0, catchData);
    notifyListeners();
  }

  void removeCatch(String id) {
    _catches.removeWhere((catch_) => catch_.id.toString() == id);
    notifyListeners();
  }

  void clearCatches() {
    _catches.clear();
    notifyListeners();
  }

  // Statistik
  double get totalWeightToday {
    return todayCatches.fold(0, (sum, item) => sum + item.weight);
  }

  int get uniqueFishTypesToday {
    return todayCatches.map((e) => e.fishName).toSet().length;
  }

  int get totalTripsToday {
    return todayCatches.length;
  }

  double get totalRevenueToday {
    return todayCatches.fold(0, (sum, item) => sum + item.totalRevenue);
  }

  double get totalWeightThisMonth {
    final now = DateTime.now();
    return _catches
        .where((c) =>
            c.departureDate.year == now.year &&
            c.departureDate.month == now.month)
        .fold(0, (sum, item) => sum + item.weight);
  }

  int get totalTripsThisMonth {
    final now = DateTime.now();
    return _catches
        .where((c) =>
            c.departureDate.year == now.year &&
            c.departureDate.month == now.month)
        .length;
  }

  double get totalRevenueThisMonth {
    final now = DateTime.now();
    return _catches
        .where((c) =>
            c.departureDate.year == now.year &&
            c.departureDate.month == now.month)
        .fold(0, (sum, item) => sum + item.totalRevenue);
  }
}