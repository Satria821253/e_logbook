import 'package:flutter/foundation.dart';
import '../models/catch_model.dart';
import '../services/api/catch_service.dart';

class CatchProvider with ChangeNotifier {
  final List<CatchModel> _catches = [];
  bool _isLoading = false;
  String? _error;

  List<CatchModel> get catches => [..._catches];
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CatchModel> get todayCatches {
    final now = DateTime.now();
    return _catches.where((catch_) {
      return catch_.departureDate.year == now.year &&
          catch_.departureDate.month == now.month &&
          catch_.departureDate.day == now.day;
    }).toList();
  }

  // Fetch catches from API
  Future<void> fetchCatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 [CatchProvider] Fetching catches from API...');
      final response = await CatchService.getCatches();
      
      if (response['success'] == true) {
        _catches.clear();
        _catches.addAll(response['data'] as List<CatchModel>);
        _error = null;
        
        debugPrint('✅ [CatchProvider] Loaded ${_catches.length} catches');
        debugPrint('📊 [CatchProvider] Total weight: ${_catches.fold<double>(0, (sum, c) => sum + c.weight)} kg');
        debugPrint('📊 [CatchProvider] Total revenue: Rp ${_catches.fold<double>(0, (sum, c) => sum + c.totalRevenue)}');
      } else {
        _error = response['message'] ?? 'Gagal mengambil data';
        debugPrint('❌ [CatchProvider] Error: $_error');
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      debugPrint('❌ CatchProvider fetchCatches error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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