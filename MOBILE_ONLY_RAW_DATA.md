# 📱 MOBILE KIRIM DATA MENTAH - PERHITUNGAN DI BACKEND

## ✅ PERUBAHAN FINAL

### 🔄 **Konsep:**
- **Mobile**: Kirim data mentah hasil tangkapan
- **Backend/Web**: Hitung harga, pajak, revenue, profit, dll

---

## 📋 **DATA YANG DIKIRIM MOBILE**

### ✅ Data Tangkapan (Raw Data):
```dart
{
  'fish_name': 'Tuna Sirip Kuning',
  'fish_type': 'Pelagis Besar',
  'weight': 50.5,                    // kg
  'quantity': 3,                     // ekor
  'condition': 'Segar',
  'crew_count': 5,
  
  // Trip Info
  'departure_date': '2026-01-28',
  'departure_time': '05:00',
  'arrival_date': '2026-01-28',
  'arrival_time': '14:30',
  'trip_duration_hours': 9,
  'trip_duration_minutes': 30,
  
  // Location
  'fishing_zone': 'WPP 711',
  'location_name': 'Laut Jawa',
  'latitude': 0.0,                   // TODO: GPS
  'longitude': 0.0,                  // TODO: GPS
  'water_depth': 50.0,               // meter
  'weather_condition': 'Cerah',
  
  // Meta
  'notes': 'Tangkapan bagus hari ini',
  'kapalId': 1,                      // Dummy
  'photo': <multipart file>
}
```

---

## ❌ **FIELD YANG DIHAPUS (Dihitung di Backend)**

| Field | Keterangan |
|-------|------------|
| `price_per_kg` | ❌ Dihapus - Backend yang tentukan harga |
| `total_revenue` | ❌ Dihapus - Backend hitung: price × weight |
| `fuel_cost` | ❌ Dihapus - Backend hitung dari data kapal |
| `operational_cost` | ❌ Dihapus - Backend hitung |
| `tax` | ❌ Dihapus - Backend hitung |
| `total_cost` | ❌ Dihapus - Backend hitung |
| `net_profit` | ❌ Dihapus - Backend hitung |

---

## 🎨 **PERUBAHAN UI**

### ❌ Section yang Dihapus:
```dart
// ❌ DIHAPUS
SectionTitle(
  title: 'Biaya Operasional',
  icon: Icons.attach_money,
),
_buildCostSection(sp, fs),
```

### ✅ Field yang Tersisa:
1. **Informasi Kapal** (read-only dari profil)
2. **Waktu Perjalanan** (departure & arrival)
3. **Hasil Tangkapan dengan AI** (nama, jenis, berat, jumlah, kondisi)
4. **Upload Foto** (camera only untuk AI)
5. **Lokasi & Kondisi** (zona, lokasi, kedalaman, cuaca, catatan)

---

## 📊 **FLOW DATA**

```
┌─────────────┐
│   MOBILE    │
│  (Crew)     │
└──────┬──────┘
       │ Kirim data mentah:
       │ - Foto ikan
       │ - Berat, jumlah
       │ - Lokasi, waktu
       │ - Kondisi
       ▼
┌─────────────┐
│   BACKEND   │
│   (API)     │
└──────┬──────┘
       │ Hitung:
       │ - Harga per kg (dari master data)
       │ - Total revenue
       │ - Biaya BBM (dari data kapal)
       │ - Biaya operasional
       │ - Pajak
       │ - Net profit
       ▼
┌─────────────┐
│     WEB     │
│  (Admin)    │
└─────────────┘
  Lihat laporan lengkap
  dengan perhitungan
```

---

## ✅ **KEUNTUNGAN PENDEKATAN INI**

1. **Konsistensi Harga**
   - Harga ikan diatur terpusat di backend
   - Tidak ada perbedaan harga antar crew

2. **Fleksibilitas**
   - Admin bisa update harga tanpa update app
   - Perhitungan pajak bisa berubah tanpa update app

3. **Keamanan**
   - Crew tidak bisa manipulasi harga
   - Perhitungan finansial terpusat

4. **Simplicity**
   - UI mobile lebih sederhana
   - Crew fokus input data tangkapan saja

---

## 🔧 **FILE YANG DIUBAH**

1. ✅ `lib/screens/crew/screens/create_catch_screen.dart`
   - Hapus field finansial (price, fuel, operational, tax)
   - Hapus method `_calculateTax()`
   - Hapus section "Biaya Operasional"
   - Pindah field "Catatan" ke section "Lokasi & Kondisi"

2. ✅ `lib/services/local/catch_submission_service.dart`
   - Hapus field finansial dari API data
   - Kirim hanya data mentah tangkapan

---

## 📝 **VALIDASI YANG TERSISA**

```dart
✅ Nama ikan harus diisi
✅ Berat > 0
✅ Minimal 1 foto
✅ Waktu keberangkatan & kedatangan
✅ Lokasi harus diisi
❌ Harga per kg (DIHAPUS)
```

---

## 🚀 **TESTING**

### Test Case:
1. Buka "Catat Tangkapan Baru"
2. Isi data:
   - ✅ Foto ikan
   - ✅ Nama, jenis, berat, jumlah
   - ✅ Waktu perjalanan
   - ✅ Lokasi & cuaca
   - ❌ TIDAK ADA input harga/biaya
3. Submit
4. Backend akan:
   - Terima data mentah
   - Hitung harga dari master data
   - Hitung biaya dari data kapal
   - Hitung pajak & profit
   - Return hasil perhitungan

---

## 📊 **CONTOH RESPONSE DARI BACKEND**

```json
{
  "success": true,
  "message": "Data tangkapan berhasil disimpan",
  "data": {
    "id": 123,
    "fish_name": "Tuna Sirip Kuning",
    "weight": 50.5,
    "quantity": 3,
    
    // Perhitungan dari backend:
    "price_per_kg": 85000,
    "total_revenue": 4292500,
    "fuel_cost": 500000,
    "operational_cost": 200000,
    "tax": 50500,
    "total_cost": 750500,
    "net_profit": 3542000,
    
    "sync_status": "Synced",
    "photoUrl": "http://api.com/uploads/catches/123.jpg"
  }
}
```

---

## ✅ SELESAI!

Mobile sekarang hanya kirim **data mentah tangkapan**, semua perhitungan finansial dilakukan di **backend/web**! 🎉
