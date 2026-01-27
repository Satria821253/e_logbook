# 📚 Dokumentasi E-Logbook

## 📋 Daftar Isi

1. [Arsitektur Aplikasi](#arsitektur-aplikasi)
2. [Struktur Folder](#struktur-folder)
3. [Fitur Utama](#fitur-utama)
4. [State Management](#state-management)
5. [Services & API](#services--api)
6. [Database Lokal](#database-lokal)
7. [Keamanan](#keamanan)
8. [Panduan Development](#panduan-development)

---

## 🏗️ Arsitektur Aplikasi

### Arsitektur Umum

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Screens, Widgets, UI Components)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         State Management Layer          │
│         (Provider Pattern)              │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Business Logic Layer           │
│    (Services, API Calls, OCR, AI)       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│            Data Layer                   │
│  (SQLite, SharedPreferences, Cache)     │
└─────────────────────────────────────────┘
```

### Design Pattern

- **State Management**: Provider Pattern
- **Architecture**: Clean Architecture (Modified)
- **Navigation**: Named Routes dengan Route Generator
- **API Client**: Dio dengan Interceptors
- **Local Storage**: SQLite + SharedPreferences

---

## 📁 Struktur Folder

### `/lib` - Source Code Utama

```
lib/
├── config/              # Konfigurasi aplikasi
│   ├── api_config.dart          # Base URL & endpoints
│   └── app_initializer.dart     # Inisialisasi app
│
├── constants/           # Data konstanta
│   └── indonesia_harbors.dart   # Data pelabuhan Indonesia
│
├── models/              # Data models
│   ├── user_model.dart          # Model user
│   ├── trip_model.dart          # Model trip/perjalanan
│   ├── catch_model.dart         # Model tangkapan
│   ├── harbor_zone.dart         # Model zona pelabuhan
│   └── zone_alert.dart          # Model alert zona
│
├── provider/            # State management
│   ├── user_provider.dart       # State user
│   ├── catch_provider.dart      # State tangkapan
│   ├── navigation_provider.dart # State navigasi
│   └── zone_alert.dart          # State alert zona
│
├── routes/              # Routing & navigation
│   ├── app_routes.dart          # Definisi routes
│   ├── route_generator.dart     # Generator routes
│   ├── common_routes.dart       # Routes umum
│   ├── crew_routes.dart         # Routes crew
│   ├── nahkoda_routes.dart      # Routes nahkoda
│   └── tracking_routes.dart     # Routes tracking
│
├── screens/             # UI Screens
│   ├── crew/                    # Fitur crew
│   ├── documents/               # Manajemen dokumen
│   │   ├── pages/               # Halaman dokumen
│   │   ├── widgets/             # Widget dokumen
│   │   └── models/              # Model dokumen
│   ├── nahkoda/                 # Fitur nahkoda
│   ├── tracking/                # GPS tracking
│   ├── vessel/                  # Manajemen kapal
│   ├── page/                    # Halaman umum
│   └── settings/                # Pengaturan
│
├── services/            # Business logic & API
│   ├── api/                     # API services
│   ├── ai/                      # AI detection (Gemini)
│   ├── ocr/                     # OCR services
│   ├── cuaca/                   # Weather API
│   ├── local/                   # Local storage
│   ├── realtime/                # Real-time services
│   ├── device/                  # Device services
│   └── nitification/            # Notification services
│
├── utils/               # Helper utilities
│   ├── token_interceptor.dart   # JWT interceptor
│   ├── account_status_interceptor.dart
│   ├── data_encryption.dart     # Enkripsi data
│   ├── input_validator.dart     # Validasi input
│   ├── cache_cleaner.dart       # Cache management
│   └── responsive_helper.dart   # Responsive UI
│
├── widgets/             # Reusable widgets
│   ├── custom_silver_appbar.dart
│   ├── custom_text_field.dart
│   ├── weather_info_card.dart
│   ├── vessel_info_card.dart
│   └── ...
│
└── main.dart            # Entry point
```

### `/assets` - Asset Files

```
assets/
├── animations/          # Lottie animations
│   ├── Click.json
│   ├── fish.json
│   ├── GPS.json
│   └── ...
├── audio/              # Sound files
│   └── alarm.m4a
└── icons/              # Custom icons
    └── icon_ai.png
```

---

## ✨ Fitur Utama

### 1. 🔐 Autentikasi & Otorisasi

**File**: `lib/screens/Login/`

- Login dengan email/password
- JWT token management
- Auto-refresh token
- Role-based access (Nahkoda/Crew)
- Account status validation

**Interceptors**:
- `TokenInterceptor`: Inject JWT token ke setiap request
- `AccountStatusInterceptor`: Validasi status akun

### 2. 🗺️ GPS Tracking Real-time

**File**: `lib/screens/tracking/`

**Fitur**:
- Real-time location tracking
- Background location service
- Polling koordinat ke server
- Offline mode dengan queue
- Battery optimization

**Services**:
- `lib/services/realtime/location_service.dart`
- `lib/services/realtime/polling_service.dart`

**Flow**:
```
GPS Device → Geolocator → Location Service → Polling Service → API
                                    ↓
                              Local Queue (offline)
```

### 3. 🐟 Manajemen Tangkapan dengan AI

**File**: `lib/screens/nahkoda/catch/`

**Fitur**:
- Foto tangkapan ikan
- AI detection dengan Gemini API
- Identifikasi jenis ikan otomatis
- Input manual berat & jumlah
- Offline sync

**Services**:
- `lib/services/ai/gemini_service.dart`

**Flow**:
```
Camera → Image → Gemini API → Fish Detection → Save to DB
                                    ↓
                              Sync to Server
```

### 4. 📄 Manajemen Dokumen dengan OCR

**File**: `lib/screens/documents/`

**Fitur**:
- Upload dokumen KTP
- OCR otomatis untuk ekstraksi data
- Camera scanner dengan frame guide
- Validasi data
- Edit manual

**Komponen**:
- `widgets/ocr/ktp_scanner_screen.dart` - Camera scanner
- `widgets/ocr/ktp_file_picker.dart` - File picker dengan animasi
- `widgets/ocr/edit_ktp_dialog.dart` - Edit dialog
- `services/ocr/ktp_ocr_service.dart` - OCR service

**Flow**:
```
Camera/Gallery → Image → OCR Service → Extract Data → Validation
                                            ↓
                                    Manual Edit (optional)
                                            ↓
                                    Upload to Server
```

**Confidence Score**:
- ≥70% = Success (hijau)
- 40-69% = Warning (kuning)
- <40% = Error (merah)

### 5. ⚓ Manajemen Vessel

**File**: `lib/screens/vessel/`

**Fitur**:
- Info kapal (nama, ukuran, kapasitas)
- Monitoring BBM
- Monitoring es
- Sertifikat kapal
- Riwayat maintenance

### 6. 🚨 Zone Alert System

**File**: `lib/provider/zone_alert.dart`

**Fitur**:
- Deteksi zona terlarang
- Alert otomatis
- Notifikasi push
- Sound alarm
- Riwayat pelanggaran

**Flow**:
```
GPS Location → Check Zone → Inside Forbidden Zone?
                                    ↓ Yes
                            Trigger Alert → Notification + Sound
                                    ↓
                            Save to History
```

### 7. 🌤️ Informasi Cuaca

**File**: `lib/services/cuaca/`

**Fitur**:
- Cuaca real-time
- Forecast 5 hari
- Wind speed & direction
- Wave height
- Visibility

**API**: OpenWeather API

### 8. 📴 Offline Mode

**Fitur**:
- SQLite local database
- Auto-sync saat online
- Queue management
- Conflict resolution

**Services**:
- `lib/services/local/local_storage_service.dart`

---

## 🔄 State Management

### Provider Pattern

**Providers**:

1. **UserProvider** (`lib/provider/user_provider.dart`)
   - User data
   - Authentication state
   - Profile management

2. **CatchProvider** (`lib/provider/catch_provider.dart`)
   - Catch data
   - Sync status
   - Offline queue

3. **NavigationProvider** (`lib/provider/navigation_provider.dart`)
   - Bottom navigation
   - Page state

4. **ZoneAlertProvider** (`lib/provider/zone_alert.dart`)
   - Zone monitoring
   - Alert state

### Penggunaan

```dart
// Di main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => CatchProvider()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ChangeNotifierProvider(create: (_) => ZoneAlertProvider()),
  ],
  child: MyApp(),
)

// Di widget
final userProvider = Provider.of<UserProvider>(context);
final user = userProvider.user;
```

### Best Practices

1. **Gunakan `addPostFrameCallback` untuk setState**:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) setState(() { /* ... */ });
});
```

2. **Check `mounted` setelah async**:
```dart
await someAsyncOperation();
if (!mounted) return;
setState(() { /* ... */ });
```

3. **Cache Provider di `didChangeDependencies`**:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _userProvider ??= Provider.of<UserProvider>(context, listen: false);
}
```

---

## 🌐 Services & API

### API Configuration

**File**: `lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.example.com';
  static const String loginEndpoint = '/auth/login';
  static const String catchEndpoint = '/catches';
  // ...
}
```

### Dio Setup dengan Interceptors

```dart
final dio = Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
));

dio.interceptors.addAll([
  TokenInterceptor(),
  AccountStatusInterceptor(),
  LogInterceptor(),
]);
```

### API Services Structure

```
services/
├── api/
│   ├── auth_service.dart        # Login, logout, refresh token
│   ├── trip_service.dart        # Trip CRUD
│   ├── catch_service.dart       # Catch CRUD
│   ├── document_service.dart    # Document upload
│   └── vessel_service.dart      # Vessel info
```

### Error Handling

```dart
try {
  final response = await dio.post('/endpoint', data: data);
  return response.data;
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Unauthorized - refresh token
  } else if (e.response?.statusCode == 403) {
    // Forbidden - account inactive
  } else {
    // Other errors
  }
  rethrow;
}
```

---

## 💾 Database Lokal

### SQLite Schema

**File**: `lib/services/local/local_storage_service.dart`

**Tables**:

1. **catches** - Data tangkapan offline
```sql
CREATE TABLE catches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  trip_id TEXT,
  fish_type TEXT,
  weight REAL,
  quantity INTEGER,
  photo_path TEXT,
  latitude REAL,
  longitude REAL,
  synced INTEGER DEFAULT 0,
  created_at TEXT
)
```

2. **locations** - Queue lokasi offline
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL,
  longitude REAL,
  timestamp TEXT,
  synced INTEGER DEFAULT 0
)
```

3. **trips** - Cache trip data
```sql
CREATE TABLE trips (
  id TEXT PRIMARY KEY,
  vessel_id TEXT,
  start_time TEXT,
  end_time TEXT,
  status TEXT,
  synced INTEGER DEFAULT 0
)
```

### SharedPreferences

**Stored Data**:
- JWT token
- User ID
- Last sync timestamp
- App settings
- Cache data

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', token);
await prefs.setString('userId', userId);
```

---

## 🔒 Keamanan

### 1. Token Management

- JWT token disimpan di SharedPreferences
- Auto-refresh sebelum expired
- Token dihapus saat logout

### 2. Data Encryption

**File**: `lib/utils/data_encryption.dart`

```dart
class DataEncryption {
  static String encrypt(String data) { /* ... */ }
  static String decrypt(String encrypted) { /* ... */ }
}
```

### 3. Input Validation

**File**: `lib/utils/input_validator.dart`

```dart
class InputValidator {
  static bool isValidEmail(String email) { /* ... */ }
  static bool isValidPhone(String phone) { /* ... */ }
  static bool isValidNIK(String nik) { /* ... */ }
}
```

### 4. Security Recommendations

⚠️ **TODO untuk Production**:

1. **Implement `flutter_secure_storage`**
   - Ganti SharedPreferences untuk token
   - Enkripsi data sensitif

2. **Certificate Pinning**
   - Pin SSL certificate
   - Prevent MITM attacks

3. **Biometric Authentication**
   - Fingerprint/Face ID
   - Optional untuk user

4. **Code Obfuscation**
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/symbols
   ```

---

## 🛠️ Panduan Development

### Setup Environment

1. **Install Flutter SDK**
```bash
flutter --version  # Pastikan ^3.8.1
```

2. **Clone & Install**
```bash
git clone <repo-url>
cd e_logbook
flutter pub get
```

3. **Setup .env**
```bash
cp .env.example .env
```

Edit `.env`:
```env
API_BASE_URL=http://your-api.com/api
OPENWEATHER_API_KEY=your_key
GOOGLE_MAPS_API_KEY=your_key
GEMINI_API_KEY=your_key
```

4. **Run**
```bash
flutter run
```

### Development Workflow

1. **Buat branch baru**
```bash
git checkout -b feature/nama-fitur
```

2. **Development**
   - Ikuti struktur folder yang ada
   - Gunakan Provider untuk state
   - Tambahkan error handling
   - Check mounted setelah async

3. **Testing**
```bash
flutter test
flutter test --coverage
```

4. **Build**
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

### Code Style

1. **Naming Convention**
   - File: `snake_case.dart`
   - Class: `PascalCase`
   - Variable: `camelCase`
   - Constant: `UPPER_SNAKE_CASE`

2. **Widget Structure**
```dart
class MyWidget extends StatefulWidget {
  final String title;
  
  const MyWidget({Key? key, required this.title}) : super(key: key);
  
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Init
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

3. **Async Best Practices**
```dart
Future<void> fetchData() async {
  try {
    final data = await api.getData();
    if (!mounted) return;
    setState(() {
      _data = data;
    });
  } catch (e) {
    if (!mounted) return;
    // Handle error
  }
}
```

### Debugging

1. **Enable logging**
```dart
print('Debug: $variable');
debugPrint('Debug message');
```

2. **Dio logging**
```dart
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

3. **Flutter DevTools**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 📊 Performance Optimization

### 1. Image Optimization

```dart
Image.file(
  file,
  cacheWidth: 800,  // Resize untuk performa
  cacheHeight: 600,
)
```

### 2. List Optimization

```dart
ListView.builder(  // Gunakan builder, bukan ListView
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 3. Lazy Loading

```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    return DataWidget(snapshot.data);
  },
)
```

### 4. Cache Management

- Clear cache berkala
- Limit cache size
- Compress images

---

## 🐛 Troubleshooting

### Common Issues

1. **setState during build**
   - Gunakan `addPostFrameCallback`
   - Check `mounted` setelah async

2. **API timeout**
   - Increase timeout duration
   - Check network connection
   - Implement retry logic

3. **GPS tidak akurat**
   - Check permission
   - Enable high accuracy mode
   - Wait for GPS fix

4. **Offline sync gagal**
   - Check queue table
   - Verify network status
   - Check API response

---

## 📞 Support

Untuk pertanyaan atau issue, hubungi tim development.

---

**Version**: 1.0.0  
**Last Updated**: 2024
