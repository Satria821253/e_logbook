# 🐛 Backend Bug Report: Missing tanggalBerlaku Field

## 📋 Issue Summary
**Endpoint:** `POST /api/mobile/vessel/:kapalId/sertifikat-jalan`  
**Problem:** Field `tanggalBerlaku` tidak tersimpan di database  
**Impact:** Tanggal berlaku sertifikat tidak muncul di mobile app  
**Priority:** 🔴 HIGH

---

## 🔍 Evidence

### Flutter Log (Mobile App)
```
📄 Submitting certificate:
   Nama: "Sertifikat Jalan 2024"
   Nomor: "SJ-001/2024"
   Tanggal: 2024-12-31
   tanggal_berlaku: "2024-12-31T00:00:00.000Z"  ✅ Dikirim dengan benar

📅 Certificate data from database:
   tanggalBerlaku raw: null  ❌ TIDAK TERSIMPAN!
   uploadedAt raw: 2026-01-23T07:33:14.986Z  ✅ Tersimpan
```

---

## 🔧 Root Cause

Backend API tidak menyimpan field `tanggal_berlaku` yang dikirim dari mobile app.

**Request dari Mobile:**
```javascript
POST /api/mobile/vessel/:kapalId/sertifikat-jalan
Content-Type: multipart/form-data

{
  nama: "Sertifikat Jalan 2024",
  nomor_sertifikat: "SJ-001/2024",
  tanggal_berlaku: "2024-12-31T00:00:00.000Z",  // ← Field ini hilang
  file: [binary data]
}
```

---

## ✅ Solution

### Backend Code Fix

**File:** `routes/vessel.js` atau `controllers/vesselController.js`

**BEFORE (Current - Broken):**
```javascript
// Upload Sertifikat Jalan
router.post('/vessel/:kapalId/sertifikat-jalan', upload.single('file'), async (req, res) => {
  try {
    const { nama, nomor_sertifikat } = req.body;  // ❌ tanggal_berlaku MISSING!
    const file = req.file;
    
    const sertifikat = await SertifikatJalan.create({
      kapal_id: req.params.kapalId,
      nama: nama,
      nomor_sertifikat: nomor_sertifikat,
      // tanggal_berlaku: ???  ← FIELD INI TIDAK ADA!
      file_path: file.path,
      uploaded_at: new Date()
    });
    
    res.json({ success: true, data: sertifikat });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

**AFTER (Fixed):**
```javascript
// Upload Sertifikat Jalan
router.post('/vessel/:kapalId/sertifikat-jalan', upload.single('file'), async (req, res) => {
  try {
    const { nama, nomor_sertifikat, tanggal_berlaku } = req.body;  // ✅ ADD tanggal_berlaku
    const file = req.file;
    
    // Validate tanggal_berlaku
    if (!tanggal_berlaku) {
      return res.status(400).json({ 
        success: false, 
        error: 'tanggal_berlaku is required' 
      });
    }
    
    const sertifikat = await SertifikatJalan.create({
      kapal_id: req.params.kapalId,
      nama: nama,
      nomor_sertifikat: nomor_sertifikat,
      tanggal_berlaku: new Date(tanggal_berlaku),  // ✅ SAVE THIS FIELD!
      file_path: file.path,
      uploaded_at: new Date()
    });
    
    res.json({ success: true, data: sertifikat });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

---

## 🗄️ Database Schema Check

Pastikan table `sertifikat_jalan` memiliki column `tanggal_berlaku`:

```sql
-- Check if column exists
DESCRIBE sertifikat_jalan;

-- If column doesn't exist, add it:
ALTER TABLE sertifikat_jalan 
ADD COLUMN tanggal_berlaku DATETIME NULL 
AFTER nomor_sertifikat;
```

**Expected Schema:**
```sql
CREATE TABLE sertifikat_jalan (
  id INT PRIMARY KEY AUTO_INCREMENT,
  kapal_id INT NOT NULL,
  nama VARCHAR(255) NOT NULL,
  nomor_sertifikat VARCHAR(100) NOT NULL,
  tanggal_berlaku DATETIME NULL,  -- ✅ THIS COLUMN MUST EXIST
  file_path VARCHAR(500) NOT NULL,
  uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kapal_id) REFERENCES kapal(id)
);
```

---

## 🧪 Testing

### 1. Test Upload via Mobile App
```
1. Open mobile app
2. Go to Vessel Info → Sertifikat Kapal
3. Upload new certificate with valid date
4. Check database: SELECT * FROM sertifikat_jalan ORDER BY id DESC LIMIT 1;
5. Verify tanggal_berlaku is NOT NULL
```

### 2. Test API Directly
```bash
curl -X POST http://localhost:3000/api/mobile/vessel/1/sertifikat-jalan \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "nama=Test Sertifikat" \
  -F "nomor_sertifikat=TEST-001" \
  -F "tanggal_berlaku=2024-12-31T00:00:00.000Z" \
  -F "file=@certificate.pdf"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "nama": "Test Sertifikat",
    "nomor_sertifikat": "TEST-001",
    "tanggal_berlaku": "2024-12-31T00:00:00.000Z",  // ✅ MUST BE PRESENT
    "file_path": "/uploads/certificates/xxx.pdf",
    "uploaded_at": "2024-01-23T07:33:14.986Z"
  }
}
```

---

## 📝 Checklist

- [ ] Add `tanggal_berlaku` to request body destructuring
- [ ] Add validation for `tanggal_berlaku`
- [ ] Save `tanggal_berlaku` to database
- [ ] Verify database column exists
- [ ] Test upload via mobile app
- [ ] Test API endpoint directly
- [ ] Verify data appears in mobile app

---

## 🚀 Deployment Steps

1. **Backup database** before making changes
2. **Add database column** if not exists
3. **Deploy backend code** with the fix
4. **Test thoroughly** with mobile app
5. **Monitor logs** for any errors

---

## 📞 Contact

**Reporter:** Flutter Developer  
**Date:** 2024-01-23  
**Mobile App Version:** 1.0.0

---

**Status:** 🔴 OPEN - Waiting for backend fix
