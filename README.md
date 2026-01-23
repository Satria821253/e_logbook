# 🐟 E-Logbook - Electronic Logbook for Fishermen

Aplikasi mobile untuk manajemen logbook elektronik nelayan dengan fitur GPS tracking, monitoring zona perairan, dan manajemen tangkapan ikan.

## ✨ Fitur Utama

- 🗺️ **Real-time GPS Tracking** - Pelacakan posisi kapal secara real-time
- 🐟 **Manajemen Tangkapan** - Pencatatan hasil tangkapan dengan AI detection (Gemini)
- 📄 **Dokumen Digital** - Upload dan validasi dokumen kapal & crew
- ⚓ **Manajemen Vessel** - Monitoring BBM, es, dan sertifikat kapal
- 🚨 **Zone Alert** - Peringatan otomatis saat memasuki zona terlarang
- 📴 **Offline Mode** - Sinkronisasi otomatis saat koneksi tersedia
- 🌤️ **Weather Info** - Informasi cuaca real-time
- 📊 **Statistik & History** - Laporan dan riwayat perjalanan

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Dart SDK ^3.8.1
- Android Studio / VS Code
- Android SDK (untuk Android)
- Xcode (untuk iOS)

### Installation

1. **Clone repository**
```bash
git clone <repository-url>
cd e_logbook
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup environment variables**
```bash
cp .env.example .env
```

Edit `.env` dan isi dengan API keys Anda:
```env
API_BASE_URL=http://your-api-url.com/api
OPENWEATHER_API_KEY=your_openweather_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
GEMINI_API_KEY=your_gemini_key
```

4. **Setup Google Maps API Key (Android)**

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

5. **Run the app**
```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── config/          # Konfigurasi app
├── constants/       # Konstanta (harbors, zones, dll)
├── models/          # Data models
├── provider/        # State management (Provider)
├── routes/          # Routing & navigation
├── screens/         # UI screens
│   ├── crew/        # Crew management
│   ├── documents/   # Document management
│   ├── nahkoda/     # Captain features
│   ├── tracking/    # GPS tracking
│   └── vessel/      # Vessel management
├── services/        # Business logic & API
│   ├── getApi/      # GET API services
│   ├── postApi/     # POST API services
│   └── local_storage/ # Local database
├── utils/           # Helper utilities
├── widgets/         # Reusable widgets
└── main.dart        # Entry point
```

## 🔧 Tech Stack

- **Framework**: Flutter 3.8.1
- **State Management**: Provider
- **HTTP Client**: Dio + HTTP
- **Local Storage**: SQLite + SharedPreferences
- **Maps**: Google Maps + Flutter Map
- **UI**: Material Design 3
- **Animations**: Lottie
- **Responsive**: flutter_screenutil

## 📦 Key Dependencies

```yaml
dependencies:
  provider: ^6.1.1              # State management
  dio: ^5.3.2                   # HTTP client
  google_maps_flutter: ^2.5.0   # Maps
  sqflite: ^2.3.0               # Local database
  geolocator: ^10.1.0           # GPS
  connectivity_plus: ^4.0.2     # Network status
  flutter_dotenv: ^5.1.0        # Environment variables
  lottie: ^3.1.2                # Animations
```

## 🔐 Security Notes

⚠️ **IMPORTANT**: Untuk production, implement:
1. `flutter_secure_storage` untuk token storage
2. Certificate pinning untuk API calls
3. Biometric authentication
4. Code obfuscation saat build

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Build

### Android
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### iOS
```bash
flutter build ios --release
```

## 🐛 Known Issues

- [ ] Polling service perlu optimization untuk battery life
- [ ] Perlu tambah unit tests untuk critical services
- [ ] Security: Implement flutter_secure_storage

## 📝 TODO

- [ ] Implement flutter_secure_storage
- [ ] Add Firebase Crashlytics
- [ ] Optimize background services
- [ ] Add comprehensive tests
- [ ] Setup CI/CD pipeline

## 👥 Team

Developed by [Your Team Name]

## 📄 License

[Your License]

---

**Version**: 1.0.0+1
