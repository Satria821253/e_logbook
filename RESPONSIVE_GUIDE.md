# 📱 Panduan Responsive Design - E-Logbook

## 🎯 Overview

Semua screen di aplikasi menggunakan **ResponsiveHelper** untuk konsistensi ukuran di berbagai device.

---

## 🔧 Setup (Sudah Selesai)

### Breakpoints Otomatis:
```dart
- Mobile: < 500px
- Small Tablet: 500-599px (7-8 inch)
- Medium Tablet: 600-767px (iPad, Galaxy Tab)
- Large Tablet: ≥ 768px (iPad Pro, Galaxy Tab S8+)
```

---

## 📖 Cara Penggunaan

### 1. **Deteksi Device Type**

```dart
// Cek apakah tablet atau mobile
final isTablet = ResponsiveHelper.isTablet(context);
final isMobile = ResponsiveHelper.isMobile(context);

// Cek orientasi
final isLandscape = ResponsiveHelper.isLandscape(context);
final isPortrait = ResponsiveHelper.isPortrait(context);

// Cek ukuran tablet (otomatis!)
final tabletSize = ResponsiveHelper.tabletSize(context);
// Return: 'mobile', 'small', 'medium', atau 'large'
```

---

### 2. **Ukuran Responsif Sederhana**

```dart
// Width
final width = ResponsiveHelper.width(
  context,
  mobile: 100,
  tablet: 150,  // Opsional, default: mobile * 1.4
);

// Height
final height = ResponsiveHelper.height(
  context,
  mobile: 50,
  tablet: 70,
);

// Font Size
final fontSize = ResponsiveHelper.font(
  context,
  mobile: 14,
  tablet: 18,
);
```

---

### 3. **Ukuran Adaptif (OTOMATIS untuk semua ukuran tablet)**

```dart
// Logo yang otomatis menyesuaikan
final logoSize = ResponsiveHelper.adaptiveValue(
  context,
  mobile: 100,           // Mobile
  smallTablet: 150,      // Tablet kecil (500-599px)
  mediumTablet: 200,     // Tablet sedang (600-767px)
  largeTablet: 250,      // Tablet besar (≥768px)
  mobileLandscape: 80,   // Mobile landscape
);

// Contoh penggunaan:
Image.asset(
  'assets/logo.png',
  width: ResponsiveHelper.adaptiveValue(
    context,
    mobile: 100,
    smallTablet: 150,
    mediumTablet: 200,
    largeTablet: 250,
  ),
)
```

---

### 4. **Padding Responsif**

```dart
// Padding semua sisi
padding: ResponsiveHelper.padding(
  context,
  mobile: 16,
  tablet: 24,
),

// Padding horizontal
padding: ResponsiveHelper.paddingHorizontal(
  context,
  mobile: 20,
  tablet: 32,
),

// Padding vertical
padding: ResponsiveHelper.paddingVertical(
  context,
  mobile: 12,
  tablet: 16,
),
```

---

### 5. **Spacing Antar Widget**

```dart
SizedBox(
  height: ResponsiveHelper.spacing(
    context,
    mobile: 16,
    tablet: 24,
  ),
)
```

---

### 6. **Image Size (Proporsi terhadap screen)**

```dart
final imageSize = ResponsiveHelper.imageSize(
  context,
  mobile: 200,  // Akan otomatis scale berdasarkan screen size
  tablet: 300,
);
```

---

## 🎨 Contoh Implementasi Lengkap

### Contoh 1: Logo Splash Screen
```dart
Widget _buildLogo(BuildContext context) {
  final logoSize = ResponsiveHelper.adaptiveValue(
    context,
    mobile: 250,
    smallTablet: 300,
    mediumTablet: 350,
    largeTablet: 400,
    mobileLandscape: 120,
  );
  
  return Image.asset(
    'assets/logo.png',
    width: logoSize,
    height: logoSize,
  );
}
```

### Contoh 2: Text Responsif
```dart
Text(
  'E-Logbook',
  style: TextStyle(
    fontSize: ResponsiveHelper.font(
      context,
      mobile: 24,
      tablet: 32,
    ),
    fontWeight: FontWeight.bold,
  ),
)
```

### Contoh 3: Container dengan Padding
```dart
Container(
  padding: ResponsiveHelper.padding(
    context,
    mobile: 16,
    tablet: 24,
  ),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(
        height: ResponsiveHelper.spacing(
          context,
          mobile: 12,
          tablet: 16,
        ),
      ),
      Text('Content'),
    ],
  ),
)
```

### Contoh 4: Button Width
```dart
SizedBox(
  width: ResponsiveHelper.buttonWidth(context),
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Submit'),
  ),
)
```

---

## ✅ Best Practices

### 1. **Gunakan adaptiveValue untuk elemen visual penting**
```dart
// ✅ GOOD - Otomatis untuk semua ukuran
final size = ResponsiveHelper.adaptiveValue(
  context,
  mobile: 100,
  smallTablet: 150,
  mediumTablet: 200,
  largeTablet: 250,
);

// ❌ AVOID - Manual untuk setiap ukuran
final size = isTablet 
    ? (tabletSize == 'large' ? 250 : tabletSize == 'medium' ? 200 : 150)
    : 100;
```

### 2. **Gunakan value() untuk ukuran sederhana**
```dart
// ✅ GOOD - Cukup 2 nilai
final padding = ResponsiveHelper.width(
  context,
  mobile: 16,
  tablet: 24,
);
```

### 3. **Konsisten di seluruh app**
```dart
// ✅ GOOD - Semua screen menggunakan ResponsiveHelper
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.padding(context, mobile: 16, tablet: 24),
      child: Text(
        'Hello',
        style: TextStyle(
          fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 18),
        ),
      ),
    );
  }
}
```

---

## 📊 Ukuran Rekomendasi

| Elemen | Mobile | Small Tablet | Medium Tablet | Large Tablet |
|--------|--------|--------------|---------------|--------------|
| **Logo** | 100-150px | 150-200px | 200-300px | 300-400px |
| **Icon** | 20-24px | 24-28px | 28-32px | 32-36px |
| **Title** | 20-24px | 24-28px | 28-32px | 32-40px |
| **Body Text** | 14-16px | 16-18px | 18-20px | 20-22px |
| **Padding** | 12-16px | 16-20px | 20-24px | 24-32px |
| **Spacing** | 8-12px | 12-16px | 16-20px | 20-24px |

---

## 🚀 Migration dari Kode Lama

### Sebelum:
```dart
final logoSize = isTablet && isLandscape 
    ? 350.0 
    : isTablet 
        ? 300.0 
        : 250.0;
```

### Sesudah:
```dart
final logoSize = ResponsiveHelper.adaptiveValue(
  context,
  mobile: 250,
  smallTablet: 300,
  mediumTablet: 350,
  largeTablet: 400,
);
```

---

## 🎯 Kesimpulan

✅ **Satu file ResponsiveHelper untuk semua screen**
✅ **Otomatis mendeteksi ukuran tablet**
✅ **Konsisten di seluruh aplikasi**
✅ **Mudah di-maintain**
✅ **Siap production**

---

**Update**: ResponsiveHelper sudah diupdate dengan threshold 500px dan support untuk small/medium/large tablet!
