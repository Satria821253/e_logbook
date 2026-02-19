# 🐟 E-Logbook - Electronic Logbook for Fishermen

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

**Aplikasi mobile untuk manajemen logbook elektronik nelayan dengan fitur GPS tracking, monitoring zona perairan, dan manajemen tangkapan ikan.**

[Features](#-fitur-utama) • [Installation](#-installation) • [Tech Stack](#-tech-stack) • [Screenshots](#-screenshots) • [Contributing](#-contributing)

</div>

---

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Struktur Project](#-struktur-project)
- [API Integration](#-api-integration)
- [Security](#-security)
- [Build & Deploy](#-build--deploy)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Fitur Utama

### 🗺️ Real-time GPS Tracking
- Pelacakan posisi kapal secara real-time
- Visualisasi rute perjalanan di peta
- History tracking dengan playback

### 🐟 Manajemen Tangkapan
- Pencatatan hasil tangkapan dengan detail lengkap
- AI detection menggunakan Google Gemini
- Upload foto tangkapan
- Statistik dan analisis hasil tangkapan

### 📄 Dokumen Digital
- Upload dokumen kapal & crew
- Validasi dokumen otomatis
- Status tracking (pending, approved, rejected)
- Notifikasi real-time untuk status dokumen

### ⚓ Manajemen Vessel
- Monitoring BBM dan es
- Manajemen sertifikat kapal
- Informasi crew dan nahkoda
- Riwayat maintenance

### 🚨 Zone Alert
- Peringatan otomatis saat memasuki zona terlarang
- Visualisasi zona di peta
- Notifikasi push real-time

### 📴 Offline Mode
- Sinkronisasi otomatis saat koneksi tersedia
- Local database dengan SQLite
- Queue management untuk data offline

### 🌤️ Weather Info
- Informasi cuaca real-time
- Prediksi cuaca untuk planning trip
- Integrasi dengan OpenWeather API

### 📊 Statistik & History
- Dashboard dengan grafik interaktif
- Laporan bulanan dan tahunan
- Export data ke PDF/Excel
- Riwayat perjalanan lengkap

---

## 📱 Screenshots

<div align="center">

| Home Screen | GPS Tracking | Catch Management |
|------------|--------------|------------------|
| ![Home](screenshots/home.png) | ![Tracking](screenshots/tracking.png) | ![Catch](screenshots/catch.png) |

| Document Upload | Statistics | Zone Alert |
|----------------|------------|------------|
| ![Document](screenshots/document.png) | ![Stats](screenshots/stats.png) | ![Alert](screenshots/alert.png) |

</div>

---

## 🔧 Tech Stack

### Framework & Language
- **Flutter** 3.8.1 - UI Framework
- **Dart** 3.8.1 - Programming Language

### State Management
- **Provider** 6.1.1 - State management solution

### Backend & API
- **Dio** 5.3.2 - HTTP client
- **REST API** - Backend communication
- **Firebase** - Push notifications (FCM)

### Database
- **SQLite** (sqflite 2.3.0) - Local database
- **SharedPreferences** - Key-value storage

### Maps & Location
- **Google Maps Flutter** 2.5.0 - Map visualization
- **Geolocator** 10.1.0 - GPS tracking
- **Flutter Map** - Alternative map solution

### AI & ML
- **Google Gemini API** - Fish detection & identification

### UI/UX
- **Material Design 3** - Design system
- **Lottie** 3.1.2 - Animations
- **FL Chart** - Interactive charts
- **flutter_screenutil** - Responsive design

### Utilities
- **connectivity_plus** 4.0.2 - Network status
- **flutter_dotenv** 5.1.0 - Environment variables
- **image_picker** - Camera & gallery access
- **permission_handler** - Runtime permissions

---

## 📦 Prerequisites

Sebelum memulai, pastikan Anda telah menginstall:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.8.1)
- [Dart SDK](https://dart.dev/get-dart) (^3.8.1)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

**Untuk Android:**
- Android SDK (API level 21+)
- Android Emulator atau Physical Device

**Untuk iOS:**
- Xcode 14+
- CocoaPods
- iOS Simulator atau Physical Device

---

## 🚀 Installation

### 1. Clone Repository

```bash
git clone https://github.com/your-username/e_logbook.git
cd e_logbook
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Environment Variables

⚠️ **PENTING**: Setiap developer HARUS generate API key SENDIRI!

```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

Edit file `.env` dan isi dengan API keys Anda:

```env
# Backend API
API_BASE_URL=https://elogbookipb.web.id/api

# Google Gemini AI (Generate di: https://aistudio.google.com/app/apikey)
GEMINI_API_KEY=YOUR_PERSONAL_API_KEY_HERE
GEMINI_MODEL=gemini-1.5-flash

# Google Maps (Generate di: https://console.cloud.google.com/google/maps-apis)
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY_HERE

# OpenWeather (Generate di: https://openweathermap.org/api)
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_KEY_HERE
```

### 4. Setup Google Maps API Key (Android)

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

### 5. Setup Firebase (Optional - untuk Push Notifications)

1. Download `google-services.json` dari Firebase Console
2. Letakkan di `android/app/`
3. Download `GoogleService-Info.plist` untuk iOS
4. Letakkan di `ios/Runner/`

### 6. Verify Installation

```bash
flutter doctor
```

Pastikan semua checklist ✅ hijau.

### 7. Run the App

```bash
# Debug mode
flutter run

# Pilih device
flutter run -d <device_id>

# Release mode
flutter run --release
```

---

## 📁 Struktur Project

```
lib/
├── config/              # Konfigurasi aplikasi
│   ├── app_initializer.dart
│   └── theme_config.dart
├── constants/           # Konstanta (harbors, zones, dll)
│   ├── harbors.dart
│   ├── zones.dart
│   └── fish_types.dart
├── models/              # Data models
│   ├── catch_model.dart
│   ├── user_model.dart
│   ├── vessel_model.dart
│   └── document_model.dart
├── provider/            # State management (Provider)
│   ├── catch_provider.dart
│   ├── user_provider.dart
│   ├── zone_alert.dart
│   └── navigation_provider.dart
├── routes/              # Routing & navigation
│   └── route_generator.dart
├── screens/             # UI screens
│   ├── crew/            # Crew management
│   ├── documents/       # Document management
│   ├── nahkoda/         # Captain features
│   ├── tracking/        # GPS tracking
│   ├── vessel/          # Vessel management
│   ├── home_screen.dart
│   └── splash_screen.dart
├── services/            # Business logic & API
│   ├── getApi/          # GET API services
│   ├── postApi/         # POST API services
│   ├── local_storage/   # Local database
│   ├── fcm/             # Firebase Cloud Messaging
│   └── realtime/        # Real-time updates
├── utils/               # Helper utilities
│   ├── navigation_helper.dart
│   ├── responsive_helper.dart
│   └── date_formatter.dart
├── widgets/             # Reusable widgets
│   ├── custom_button.dart
│   ├── custom_appbar.dart
│   └── loading_indicator.dart
└── main.dart            # Entry point
```

---

## 🔌 API Integration

### Base URL
```
https://elogbookipb.web.id/api
```

### Authentication
Aplikasi menggunakan token-based authentication:

```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

### Main Endpoints

#### Authentication
- `POST /login` - User login
- `POST /register` - User registration
- `POST /logout` - User logout

#### Catches
- `GET /catches` - Get all catches
- `POST /catches` - Create new catch
- `PUT /catches/{id}` - Update catch
- `DELETE /catches/{id}` - Delete catch

#### Documents
- `GET /documents` - Get user documents
- `POST /documents/upload` - Upload document
- `GET /documents/status` - Check document status

#### Tracking
- `POST /tracking/start` - Start tracking
- `POST /tracking/update` - Update position
- `POST /tracking/stop` - Stop tracking

---

## 🔐 Security

### API Key Security

⚠️ **CRITICAL - Jangan commit API keys ke Git!**

**Kenapa API Key Bisa Di-Block?**
1. ❌ API key di-commit ke GitHub (public/private)
2. ❌ API key di-share antar developer
3. ❌ Google bot auto-detect dan suspend key
4. ❌ Banyak IP berbeda pakai 1 key = suspicious

**Best Practices:**
- ✅ Setiap developer generate key sendiri
- ✅ Simpan di file `.env` (sudah di `.gitignore`)
- ✅ JANGAN PERNAH commit atau share API key
- ✅ Rotate keys secara berkala

### Production Security Checklist

- [ ] Implement `flutter_secure_storage` untuk token storage
- [ ] Enable certificate pinning untuk API calls
- [ ] Implement biometric authentication
- [ ] Enable code obfuscation saat build
- [ ] Setup ProGuard rules (Android)
- [ ] Enable App Transport Security (iOS)

---

## 📦 Build & Deploy

### Android

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

#### App Bundle (untuk Google Play)
```bash
flutter build appbundle --release
```

### iOS

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release
```

### Build Size Optimization

```bash
# Analyze build size
flutter build apk --analyze-size

# Split APK by ABI
flutter build apk --split-per-abi
```

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## 🐛 Known Issues

- [ ] Polling service perlu optimization untuk battery life
- [ ] Perlu tambah unit tests untuk critical services
- [ ] Offline sync kadang delay saat network unstable

---

## 📝 TODO

- [ ] Implement flutter_secure_storage
- [ ] Add Firebase Crashlytics
- [ ] Optimize background services
- [ ] Add comprehensive tests (target: 80% coverage)
- [ ] Setup CI/CD pipeline (GitHub Actions)
- [ ] Add dark mode support
- [ ] Implement multi-language support (i18n)
- [ ] Add export to PDF/Excel feature

---

## 🤝 Contributing

Kontribusi sangat diterima! Silakan ikuti langkah berikut:

1. Fork repository ini
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments untuk logic yang kompleks
- Write tests untuk new features
- Update documentation jika diperlukan

---

## 👥 Team

Developed by **Makerindo Team**

- **Project Manager**: [Name]
- **Lead Developer**: [Name]
- **Backend Developer**: [Name]
- **UI/UX Designer**: [Name]

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact & Support

- **Email**: support@elogbook.com
- **Website**: https://elogbookipb.web.id
- **Issues**: [GitHub Issues](https://github.com/your-username/e_logbook/issues)

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Google Gemini](https://ai.google.dev) - AI fish detection
- [OpenWeather](https://openweathermap.org) - Weather data
- [Google Maps](https://developers.google.com/maps) - Maps integration

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ by Makerindo Team

</div>
