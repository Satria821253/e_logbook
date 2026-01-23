# Backend Ice Data API Issue

## Problem Description

The GET endpoint for ice data is returning a 500 Internal Server Error:

```
GET http://210.79.191.17:5000/api/mobile/vessel/2/ice-data
```

**Error Response:**
```json
{
  "success": false,
  "message": "Unknown column 'dataEs' in 'field list'"
}
```

## Root Cause

The backend SQL query is trying to select a column named `dataEs` that doesn't exist in the database table. This is a database schema mismatch issue.

## Expected API Response Format

Based on the Flutter implementation, the API should return:

```json
{
  "success": true,
  "data": {
    "kapal": {
      "id": 2,
      "namaKapal": "KM Mina Jaya",
      "nomorRegistrasi": "REG-001"
    },
    "iceData": [
      {
        "id": "1",
        "jenisEs": "Es Balok",
        "jumlahKg": 100,
        "totalHarga": 500000,
        "tanggalPembelian": "2026-01-23T09:26:33.008Z",
        "lokasiPembelian": "Pelabuhan A",
        "buktiFileUrl": "https://example.com/bukti.jpg"
      }
    ]
  }
}
```

## Backend Fix Required

The backend developer needs to:

1. **Check the database schema** for the ice data table
2. **Identify the correct column name** (likely one of these):
   - `ice_data`
   - `iceData`
   - `data_es`
   - Or check the actual table structure

3. **Update the SQL query** in the backend controller/model to use the correct column name

4. **Verify the table structure** matches the expected response format

## Testing After Fix

Once the backend is fixed, test using:

### 1. Direct API Test (cURL)
```bash
curl -X 'GET' \
  'http://210.79.191.17:5000/api/mobile/vessel/2/ice-data' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer YOUR_TOKEN_HERE'
```

### 2. Flutter App Test
1. Open the app
2. Navigate to: **Vessel Management → Ice Data**
3. The screen should display ice purchase records
4. If no data exists, it will show "Belum ada data es"

## Related Files

### Flutter Implementation (Already Complete)
- `lib/services/getApi/vessel_service.dart` - Contains `getIceData()` method
- `lib/screens/vessel/vessel_ice_screen.dart` - Displays ice data list
- `lib/screens/vessel/ice_management_screen.dart` - Form to add ice data

### Backend Files to Check
- Ice data controller/route handler
- Ice data model/repository
- Database migration files
- Database schema for ice data table

## Contact

If you need clarification on the expected data format or API contract, please refer to this document or contact the Flutter development team.

---

**Status:** 🔴 Waiting for backend fix
**Priority:** High
**Assigned to:** Backend Team
