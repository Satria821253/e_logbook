# 📊 Implementasi Database untuk Provider

## ❌ YANG BELUM ADA DATABASE

### 1. **CatchProvider** - 🔴 PRIORITAS TINGGI

#### Masalah:
- Data tangkapan hanya di memory (List)
- Hilang saat restart app
- Tidak ada persistensi

#### Solusi:

**File**: `lib/provider/catch_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/catch_model.dart';

class CatchProvider with ChangeNotifier {
  final List<CatchModel> _catches = [];
  Database? _database;

  List<CatchModel> get catches => [..._catches];

  // Initialize database
  Future<void> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'catches.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE catches(
            id TEXT PRIMARY KEY,
            fish_name TEXT,
            fish_type TEXT,
            weight REAL,
            quantity INTEGER,
            condition TEXT,
            crew_count INTEGER,
            departure_date TEXT,
            departure_time TEXT,
            arrival_date TEXT,
            arrival_time TEXT,
            trip_duration_hours INTEGER,
            trip_duration_minutes INTEGER,
            fishing_zone TEXT,
            location_name TEXT,
            latitude REAL,
            longitude REAL,
            water_depth REAL,
            weather_condition TEXT,
            notes TEXT,
            photo_path TEXT,
            kapal_id INTEGER,
            total_revenue REAL,
            created_at TEXT
          )
        ''');
      },
    );
    
    await loadCatches();
  }

  // Load catches from database
  Future<void> loadCatches() async {
    if (_database == null) return;
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'catches',
      orderBy: 'created_at DESC',
    );
    
    _catches.clear();
    for (var map in maps) {
      _catches.add(CatchModel.fromMap(map));
    }
    
    notifyListeners();
  }

  // Add catch (save to DB)
  Future<void> addCatch(CatchModel catchData) async {
    _catches.insert(0, catchData);
    
    if (_database != null) {
      await _database!.insert(
        'catches',
        catchData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    notifyListeners();
  }

  // Remove catch (delete from DB)
  Future<void> removeCatch(String id) async {
    _catches.removeWhere((catch_) => catch_.id.toString() == id);
    
    if (_database != null) {
      await _database!.delete(
        'catches',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    notifyListeners();
  }

  // Clear all catches
  Future<void> clearCatches() async {
    _catches.clear();
    
    if (_database != null) {
      await _database!.delete('catches');
    }
    
    notifyListeners();
  }

  // Existing methods tetap sama...
  double get totalWeightToday { /* ... */ }
  int get uniqueFishTypesToday { /* ... */ }
  // dst...
}
```

**Update di `main.dart`**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _setInitialOrientation();
  final initialized = await AppInitializer.initialize();

  // Initialize CatchProvider database
  final catchProvider = CatchProvider();
  await catchProvider.initDatabase();

  runApp(
    initialized
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => UserProvider()),
              ChangeNotifierProvider.value(value: catchProvider), // Use .value
              ChangeNotifierProvider(create: (_) => ZoneAlertProvider()),
              ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ],
            child: const MyApp(),
          )
        : const InitializationErrorScreen(),
  );
}
```

**Update `CatchModel`** (tambahkan toMap/fromMap):
```dart
class CatchModel {
  // Existing fields...

  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'fish_name': fishName,
      'fish_type': fishType,
      'weight': weight,
      'quantity': quantity,
      'condition': condition,
      'crew_count': crewCount,
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
      'notes': notes,
      'photo_path': photoPath,
      'kapal_id': kapalId,
      'total_revenue': totalRevenue,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory CatchModel.fromMap(Map<String, dynamic> map) {
    return CatchModel(
      id: int.parse(map['id']),
      fishName: map['fish_name'],
      fishType: map['fish_type'],
      weight: map['weight'],
      quantity: map['quantity'],
      condition: map['condition'],
      crewCount: map['crew_count'],
      departureDate: DateTime.parse(map['departure_date']),
      departureTime: map['departure_time'],
      arrivalDate: DateTime.parse(map['arrival_date']),
      arrivalTime: map['arrival_time'],
      tripDurationHours: map['trip_duration_hours'],
      tripDurationMinutes: map['trip_duration_minutes'],
      fishingZone: map['fishing_zone'],
      locationName: map['location_name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      waterDepth: map['water_depth'],
      weatherCondition: map['weather_condition'],
      notes: map['notes'],
      photoPath: map['photo_path'],
      kapalId: map['kapal_id'],
    );
  }
}
```

---

### 2. **ZoneAlertProvider** - 🟡 PRIORITAS SEDANG

#### Masalah:
- Alert hilang saat restart
- Ada TODO untuk loadAlerts() dan saveAlerts()

#### Solusi (Simple - pakai SharedPreferences):

**File**: `lib/provider/zone_alert.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_logbook/models/zone_alert.dart';
import 'package:flutter/foundation.dart';

class ZoneAlertProvider with ChangeNotifier {
  final List<ZoneAlert> _alerts = [];
  static const String _storageKey = 'zone_alerts';

  List<ZoneAlert> get alerts => [..._alerts];
  // ... existing getters ...

  /// Load alerts dari storage
  Future<void> loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_storageKey);
      
      if (alertsJson != null) {
        final List<dynamic> decoded = jsonDecode(alertsJson);
        _alerts.clear();
        _alerts.addAll(decoded.map((e) => ZoneAlert.fromJson(e)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  /// Save alerts ke storage
  Future<void> saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = jsonEncode(_alerts.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, alertsJson);
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }

  /// Tambah alert baru (dengan auto-save)
  Future<void> addAlert(ZoneAlert alert) async {
    _alerts.insert(0, alert);
    await saveAlerts();
    notifyListeners();
  }

  /// Tandai alert sebagai sudah dibaca (dengan auto-save)
  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      await saveAlerts();
      notifyListeners();
    }
  }

  // Update semua method lain untuk auto-save...
}
```

**Update `ZoneAlert` model** (tambahkan toJson/fromJson):
```dart
class ZoneAlert {
  // Existing fields...

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vessel_name': vesselName,
      'zone_name': zoneName,
      'alert_type': alertType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_read': isRead,
    };
  }

  factory ZoneAlert.fromJson(Map<String, dynamic> json) {
    return ZoneAlert(
      id: json['id'],
      vesselName: json['vessel_name'],
      zoneName: json['zone_name'],
      alertType: json['alert_type'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      isRead: json['is_read'] ?? false,
    );
  }
}
```

---

## 📋 CHECKLIST IMPLEMENTASI

### CatchProvider (PRIORITAS 1):
- [ ] Tambah method `initDatabase()`
- [ ] Tambah method `loadCatches()`
- [ ] Update `addCatch()` untuk save ke DB
- [ ] Update `removeCatch()` untuk delete dari DB
- [ ] Update `clearCatches()` untuk clear DB
- [ ] Tambah `toMap()` dan `fromMap()` di CatchModel
- [ ] Update `main.dart` untuk init database

### ZoneAlertProvider (PRIORITAS 2):
- [ ] Implement `loadAlerts()` dengan SharedPreferences
- [ ] Implement `saveAlerts()` dengan SharedPreferences
- [ ] Update semua method untuk auto-save
- [ ] Tambah `toJson()` dan `fromJson()` di ZoneAlert
- [ ] Call `loadAlerts()` di app startup

---

## 🧪 TESTING

### Test CatchProvider:
1. Tambah tangkapan baru
2. Restart app
3. ✅ Data tangkapan masih ada

### Test ZoneAlertProvider:
1. Trigger zone alert
2. Restart app
3. ✅ Alert masih ada

---

## ⚠️ CATATAN

**NavigationProvider** TIDAK PERLU database karena:
- Hanya menyimpan UI state (index 0-3)
- Tidak perlu persistensi
- Reset ke 0 setiap app start adalah behavior yang diinginkan
