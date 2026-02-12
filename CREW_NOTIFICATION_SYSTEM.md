# Dokumentasi Sistem Notifikasi Crew

## 📋 Overview
Sistem notifikasi untuk crew yang diatur berdasarkan user ID dan role dengan ketentuan khusus untuk akses tracking.

## 🎯 Ketentuan Notifikasi

### Nahkoda
- ✅ Menerima notifikasi tugas baru saat ditugaskan
- ✅ Menerima notifikasi 2 jam sebelum keberangkatan
- ✅ Bisa akses tracking 1 hari (24 jam) sebelum departure
- ✅ Notifikasi hanya muncul jika tidak ada trip aktif sebelumnya

### Crew (ABK)
- ✅ Menerima notifikasi tugas baru saat ditugaskan
- ❌ TIDAK menerima notifikasi 2 jam sebelum keberangkatan
- ❌ TIDAK menerima notifikasi saat departure
- ✅ HANYA menerima notifikasi saat status trip berubah menjadi "berlayar"
- ✅ Hanya bisa akses tracking saat status "berlayar"
- ✅ Notifikasi hanya muncul jika tidak ada trip aktif sebelumnya

## 🔔 Jenis Notifikasi

### 1. Notifikasi Tugas Baru (`new_task`)
**Untuk**: Nahkoda & Crew
**Kondisi**: 
- Tidak ada trip aktif (status: aktif, berlayar, disetujui)
- User ID sesuai dengan penerima notifikasi
- Notifikasi belum dibaca

**Implementasi**:
```dart
// my_schedules_screen.dart
final newTaskNotif = myNotifications.firstWhere(
  (n) => n['type'] == 'new_task' && n['isRead'] == false,
  orElse: () => null,
);

if (newTaskNotif != null && !_hasActiveTrip) {
  await LocalNotificationService.showNewTaskNotification(...);
}
```

### 2. Notifikasi Status Berlayar (`trip_berlayar`)
**Untuk**: Crew ONLY
**Kondisi**:
- Status trip berubah menjadi "berlayar"
- User adalah crew dari trip tersebut
- Notifikasi belum dibaca

**Implementasi**:
```dart
// my_schedules_screen.dart
if (userRole.toLowerCase() == 'crew' || userRole.toLowerCase() == 'abk') {
  final berlayarNotif = myNotifications.firstWhere(
    (n) => n['type'] == 'trip_berlayar' && n['isRead'] == false,
    orElse: () => null,
  );
  
  if (berlayarNotif != null) {
    await LocalNotificationService.showNewTaskNotification(...);
  }
}
```

### 3. Notifikasi 2 Jam Sebelum (`trip_reminder`)
**Untuk**: Nahkoda ONLY
**Kondisi**:
- 2 jam sebelum waktu keberangkatan
- Crew TIDAK menerima notifikasi ini

**Implementasi**:
```dart
// trip_schedule_notification_service.dart
// Hanya kirim ke nahkoda, skip crew
await LocalNotificationService.showNotification(
  id: trip.id * 100 + 1,
  title: '⏰ Persiapan Keberangkatan',
  body: '2 jam lagi trip akan dimulai...',
);
```

## 🔐 Validasi User ID

Semua notifikasi difilter berdasarkan user ID:

```dart
// Filter notifikasi berdasarkan user ID
final myNotifications = notifications.where((n) {
  final recipientId = n['userId'] ?? n['recipientId'];
  return recipientId == currentUserId;
}).toList();
```

## 🚫 Blokir Notifikasi Jika Ada Trip Aktif

```dart
// Cek apakah ada trip aktif
final hasActive = allTrips.any((trip) {
  final isMyTrip = (nahkodaId == currentUserId) || 
                   (awakKapal != null && awakKapal.contains(currentUserId));
  return isMyTrip && (status == 'aktif' || status == 'berlayar' || status == 'disetujui');
});

// Hanya tampilkan notifikasi jika tidak ada trip aktif
if (!hasActive) {
  await LocalNotificationService.showNewTaskNotification(...);
}
```

## 📱 FAB Crew (Floating Action Button)

FAB crew bergantian otomatis berdasarkan status trip:

### Saat Tidak Berlayar
- Icon: 📷 (Add Photo)
- Fungsi: Create Catch Screen
- Warna: Gradient Blue

### Saat Berlayar
- Icon: 🚢 (Lottie Animation)
- Fungsi: Crew Tracking Button
- Warna: Blue Border + Shadow

**Implementasi**:
```dart
// crew_floating_menu.dart
_isBerlayar
  ? const CrewTrackingButton()
  : GestureDetector(
      onTap: () => Navigator.push(...CreateCatchScreen()),
      child: Container(...),
    )
```

## 🔄 Auto Refresh

Sistem melakukan pengecekan otomatis:

1. **Notifikasi**: Setiap 30 detik
   ```dart
   Timer.periodic(Duration(seconds: 30), (timer) async {
     await _checkNewTaskNotification();
   });
   ```

2. **Status Trip (FAB)**: Setiap 30 detik
   ```dart
   Timer.periodic(Duration(seconds: 30), (timer) {
     if (mounted) _checkTripStatus();
   });
   ```

## 📊 Flow Diagram

```
Admin Assign Trip
       ↓
   [Nahkoda]                    [Crew]
       ↓                            ↓
✅ Notif Tugas Baru          ✅ Notif Tugas Baru
       ↓                            ↓
✅ Bisa Akses 1 Hari         ❌ Belum Bisa Akses
   Sebelum Departure              Tracking
       ↓                            ↓
✅ Notif 2 Jam Sebelum       ❌ Tidak Ada Notif
       ↓                            ↓
   Nahkoda Mulai Trip              ↓
       ↓                            ↓
   Status: BERLAYAR          ✅ Notif Berlayar
       ↓                            ↓
   Tracking Aktif            ✅ Bisa Akses Tracking
```

## 🔧 File yang Dimodifikasi

1. `lib/constants/tracking_constants.dart`
   - Tambah validasi status untuk crew

2. `lib/screens/schedules/my_schedules_screen.dart`
   - Filter notifikasi berdasarkan user ID
   - Tambah notifikasi berlayar untuk crew
   - Blokir notifikasi jika ada trip aktif

3. `lib/services/nitification/trip_schedule_notification_service.dart`
   - Crew tidak menerima notif 2 jam sebelum
   - Crew tidak menerima notif departure
   - Tambah fungsi sendBerlayarNotification()

4. `lib/screens/crew/widgets/crew_tracking_button.dart` (BARU)
   - Widget tracking khusus crew
   - Validasi status berlayar

5. `lib/screens/crew/widgets/crew_floating_menu.dart`
   - FAB bergantian otomatis
   - Auto refresh status trip

## ✅ Testing Checklist

- [ ] Nahkoda menerima notif tugas baru (jika tidak ada trip aktif)
- [ ] Crew menerima notif tugas baru (jika tidak ada trip aktif)
- [ ] Crew TIDAK menerima notif jika ada trip aktif
- [ ] Crew TIDAK menerima notif 2 jam sebelum
- [ ] Crew menerima notif saat status berlayar
- [ ] FAB crew berubah saat status berlayar
- [ ] Tracking crew hanya bisa diakses saat berlayar
- [ ] Notifikasi difilter berdasarkan user ID
- [ ] Tidak ada duplikasi notifikasi

## 🎯 Kesimpulan

Sistem notifikasi sekarang:
1. ✅ Diatur berdasarkan user ID
2. ✅ Diatur berdasarkan role (nahkoda/crew)
3. ✅ Crew hanya notif saat berlayar
4. ✅ Tidak ada notif jika ada trip aktif
5. ✅ FAB crew bergantian otomatis
6. ✅ Auto refresh setiap 30 detik
