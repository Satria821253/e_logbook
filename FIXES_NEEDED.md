# 🔧 PERBAIKAN YANG DIBUTUHKAN - Create Catch Screen

## ❌ MASALAH KRITIS

### 1. **kapalId Tidak Dikirim ke API**
**File**: `create_catch_screen.dart` line ~400

**Masalah**:
```dart
// ❌ TIDAK ADA kapalId
final catchData = {
  'vesselName': user!.vesselName!,
  'vesselNumber': user.vesselNumber!,
  // kapalId HILANG!
};
```

**Solusi**:
```dart
// ✅ TAMBAHKAN kapalId
final catchData = {
  'kapalId': user!.vesselId!,  // Perlu tambah di UserModel
  'vesselName': user.vesselName!,
  'vesselNumber': user.vesselNumber!,
};
```

**Action Required**:
1. Tambah `vesselId` di `UserModel`
2. Simpan `vesselId` saat login
3. Kirim `kapalId` ke API

---

### 2. **Field Mapping Salah**
**File**: `create_catch_screen.dart` line ~400

**Masalah**:
```dart
// ❌ SALAH - Hardcoded N/A
'fishingZone': 'N/A',
'locationName': 'N/A',
'latitude': 0.0,
'longitude': 0.0,
```

**Solusi**:
```dart
// ✅ BENAR - Gunakan data real
'fishingZone': _harborController.text.isEmpty ? 'N/A' : _harborController.text,
'locationName': _fishingGearController.text.isEmpty ? 'N/A' : _fishingGearController.text,
'latitude': _currentLatitude ?? 0.0,  // Dari GPS
'longitude': _currentLongitude ?? 0.0, // Dari GPS
```

---

### 3. **Harga & Revenue = 0**
**File**: `create_catch_screen.dart` line ~390

**Masalah**:
```dart
// ❌ SALAH - Selalu 0
final totalRevenue = 0;
'pricePerKg': 0,
'totalRevenue': 0,
```

**Solusi**:
```dart
// ✅ BENAR - Hitung dari input
final pricePerKg = double.tryParse(_priceController.text) ?? 0;
final totalRevenue = pricePerKg * weight;

'pricePerKg': pricePerKg,
'totalRevenue': totalRevenue,
```

---

### 4. **Label UI Salah**
**File**: `create_catch_screen.dart` line ~1100

**Masalah**:
```dart
// ❌ SALAH - Controller name tidak sesuai label
TextFormField(
  controller: _fishingGearController,  // Nama controller untuk "alat tangkap"
  decoration: InputDecoration(
    labelText: 'Nama Lokasi',  // Tapi label "Nama Lokasi"
  ),
),
```

**Solusi**:
```dart
// ✅ BENAR - Rename controller atau ganti label
// OPSI 1: Ganti nama controller
final _locationNameController = TextEditingController();

// OPSI 2: Tambah controller baru untuk alat tangkap
final _fishingGearController = TextEditingController(); // Untuk alat tangkap
final _locationNameController = TextEditingController(); // Untuk nama lokasi
```

---

## ⚠️ MASALAH MENENGAH

### 5. **GPS Coordinates Tidak Diambil**
**File**: `create_catch_screen.dart`

**Masalah**: Tidak ada kode untuk ambil GPS coordinates

**Solusi**:
```dart
// Tambah state variables
double? _currentLatitude;
double? _currentLongitude;

// Tambah method untuk get GPS
Future<void> _getCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
    });
  } catch (e) {
    print('Error getting location: $e');
  }
}

// Panggil di initState atau saat user klik button
```

---

### 6. **tripId Tidak Ada**
**File**: `create_catch_screen.dart`

**Masalah**: API punya optional field `tripId`, tapi UI tidak kirim

**Solusi**:
```dart
// Jika ada fitur trip tracking, tambahkan:
'tripId': currentTripId, // Dari trip tracking service
```

---

## 📋 CHECKLIST PERBAIKAN

### Priority 1 (CRITICAL):
- [ ] Tambah `vesselId` di `UserModel`
- [ ] Kirim `kapalId` ke API
- [ ] Fix field mapping (fishingZone, locationName)
- [ ] Fix harga & revenue calculation

### Priority 2 (HIGH):
- [ ] Implementasi GPS coordinates
- [ ] Fix label UI yang salah
- [ ] Tambah validation untuk required fields

### Priority 3 (MEDIUM):
- [ ] Implementasi tripId (jika ada trip tracking)
- [ ] Tambah error handling untuk API call
- [ ] Tambah loading state saat submit

---

## 🔍 FILE YANG PERLU DIUBAH

1. **lib/models/user_model.dart**
   - Tambah field `vesselId`

2. **lib/screens/crew/screens/create_catch_screen.dart**
   - Fix line ~390: Hitung totalRevenue
   - Fix line ~400: Tambah kapalId, fix field mapping
   - Fix line ~1100: Rename controller atau label
   - Tambah GPS location tracking

3. **lib/services/local/catch_submission_service.dart**
   - Implementasi real API call di `_sendToServer()`
   - Map field names sesuai API spec

---

## 📝 CONTOH KODE LENGKAP

### UserModel dengan vesselId:
```dart
class UserModel {
  final String name;
  final String? vesselId;      // ✅ TAMBAH INI
  final String? vesselName;
  final String? vesselNumber;
  // ... fields lainnya
}
```

### Catch Data yang Benar:
```dart
final pricePerKg = double.tryParse(_priceController.text) ?? 0;
final totalRevenue = pricePerKg * weight;

final catchData = {
  'id': catchId,
  'fishName': _fishNameController.text,
  'fishType': _selectedFishType,
  'weight': weight,
  'quantity': int.tryParse(_quantityController.text) ?? 0,
  'condition': _selectedCondition,
  'crew_count': user.crewCount!,
  'price_per_kg': pricePerKg,                    // ✅ FIX
  'total_revenue': totalRevenue,                 // ✅ FIX
  'departure_date': _departureDate.toIso8601String(),
  'departure_time': _departureTime.format(context),
  'arrival_date': _arrivalDate.toIso8601String(),
  'arrival_time': _arrivalTime.format(context),
  'trip_duration_hours': _calculatedHours,
  'trip_duration_minutes': _calculatedMinutes,
  'fishing_zone': _harborController.text,        // ✅ FIX
  'location_name': _locationNameController.text, // ✅ FIX (perlu controller baru)
  'latitude': _currentLatitude ?? 0.0,           // ✅ FIX
  'longitude': _currentLongitude ?? 0.0,         // ✅ FIX
  'water_depth': double.tryParse(_waterDepthController.text) ?? 0,
  'weather_condition': _selectedWeatherCondition,
  'fuel_cost': fuelCost,
  'operational_cost': operationalCost,
  'tax': tax,
  'total_cost': totalCost,
  'net_profit': netProfit,
  'notes': _notesController.text.isEmpty ? null : _notesController.text,
  'kapalId': user.vesselId!,                     // ✅ FIX
  'tripId': currentTripId,                       // ✅ OPTIONAL
};
```

---

## 🚀 ESTIMASI WAKTU PERBAIKAN

- **Priority 1**: 2-3 jam
- **Priority 2**: 2-3 jam
- **Priority 3**: 1-2 jam

**Total**: 5-8 jam development time
