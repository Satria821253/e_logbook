import 'package:e_logbook/screens/documents/models/ktp_ocr_result.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KTPOCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Dispose the recognizer when not needed
  static void dispose() {
    _textRecognizer.close();
  }

  /// Extract KTP data from image file
  static Future<KTPOCRResult> extractKTPData(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return _parseKTPText(recognizedText.text);
    } catch (e) {
      throw Exception('Gagal memproses gambar: $e');
    }
  }

  /// Parse recognized text to extract KTP fields
  static KTPOCRResult _parseKTPText(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // Debug: Print all recognized lines
    print('🔍 OCR Recognized Lines:');
    for (int i = 0; i < lines.length; i++) {
      print('  [$i] ${lines[i]}');
    }
    
    String? nik;
    String? nama;
    String? tempatLahir;
    String? tanggalLahir;
    String? jenisKelamin;
    String? golonganDarah;
    String? alamat;
    String? rtRw;
    String? kelDesa;
    String? kecamatan;
    String? agama;
    String? statusPerkawinan;
    String? pekerjaan;
    String? kewarganegaraan;
    String? berlakuHingga;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      final originalLine = lines[i];

      // NIK - format ":3171234567890123" (16 digit, bisa ada spasi)
      if (nik == null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim().replaceAll(' ', ''); // Hapus spasi
        if (_isNIK(value)) {
          nik = value;
          print('  ✅ NIK found: $nik');
        }
      }

      // Nama - format ":MIRA SETIAWAN" (setelah NIK, bukan NIK, tidak ada koma)
      if (nama == null && nik != null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        // Pastikan BUKAN NIK, bukan tempat lahir (tidak ada koma), bukan tanggal, minimal 3 karakter
        if (!_isNIK(value) && !value.contains(',') && !_isDatePattern(value) && value.length > 3) {
          nama = value;
          print('  ✅ Nama found: $nama');
        }
      }

      // Tempat/Tgl Lahir - format ": JAKARTA, 18-02-1986"
      if (tempatLahir == null && tanggalLahir == null && nama != null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        if (value.contains(',')) {
          final parts = value.split(',').map((e) => e.trim()).toList();
          tempatLahir = parts[0];
          if (parts.length > 1) tanggalLahir = parts[1];
          print('  ✅ Tempat/Tanggal found: $tempatLahir, $tanggalLahir');
        }
      }

      // Jenis Kelamin - format ": PEREMPUAN" atau "JENIS KELAMIN"
      if (jenisKelamin == null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim().toUpperCase();
        if (value == 'PEREMPUAN' || value == 'LAKI-LAKI') {
          jenisKelamin = value;
          print('  ✅ Jenis Kelamin found: $jenisKelamin');
        }
      }

      // Alamat - format ":JL. PASTI CEPAT A7/66" (setelah jenis kelamin)
      if (alamat == null && jenisKelamin != null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        if (value.contains('JL') || value.contains('JALAN') || value.length > 15) {
          alamat = value;
          print('  ✅ Alamat found: $alamat');
        }
      }

      // RT/RW - format ": 007/008"
      if (rtRw == null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        if (value.contains('/') && value.length < 10) {
          rtRw = value;
          print('  ✅ RT/RW found: $rtRw');
        }
      }

      // Kel/Desa - format ":PEGADUNGAN" (setelah RT/RW)
      if (kelDesa == null && rtRw != null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        if (!value.contains('/') && value.length < 30 && !value.contains(',')) {
          kelDesa = value;
          print('  ✅ Kel/Desa found: $kelDesa');
        }
      }

      // Kecamatan - format ": KALIDERES" atau "KALIDERES" (setelah Kel/Desa, bisa tanpa ":")
      if (kecamatan == null && kelDesa != null) {
        if (originalLine.startsWith(':')) {
          final value = originalLine.substring(1).trim();
          if (value.length < 30 && !value.contains('PEGAWAI') && !value.contains('SWASTA') && !value.contains('PNS') && value != kelDesa) {
            kecamatan = value;
            print('  ✅ Kecamatan found: $kecamatan');
          }
        } else if (!originalLine.startsWith(':') && line.length < 30 && line.length > 2) {
          if (!line.contains('PROVINSI') && !line.contains('STATUS') && !line.contains('PEKERJAAN') && !line.contains('GOL') && originalLine != kelDesa) {
            kecamatan = originalLine;
            print('  ✅ Kecamatan found: $kecamatan');
          }
        }
      }

      // Agama - format ":ISLAM" (setelah kecamatan)
      if (agama == null && kecamatan != null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim().toUpperCase();
        if (value == 'ISLAM' || value == 'KRISTEN' || value == 'KATOLIK' || value == 'HINDU' || value == 'BUDDHA' || value == 'KONGHUCU') {
          agama = value;
          print('  ✅ Agama found: $agama');
        }
      }

      // Pekerjaan - format ": PEGAWAI SWASTA"
      if (pekerjaan == null && originalLine.startsWith(':')) {
        final value = originalLine.substring(1).trim();
        if (value.contains('PEGAWAI') || value.contains('WIRASWASTA') || value.contains('PNS')) {
          pekerjaan = value;
          print('  ✅ Pekerjaan found: $pekerjaan');
        }
      }

      // Golongan Darah - format "Gol. Darah : B"
      if (golonganDarah == null && line.contains('GOL') && line.contains('DARAH')) {
        golonganDarah = _extractValue(line);
        if (golonganDarah.isNotEmpty) {
          print('  ✅ Gol. Darah found: $golonganDarah');
        }
      }

      // Status Perkawinan
      if (line.contains('STATUS PERKAWINAN')) {
        statusPerkawinan = _extractValue(line);
      }

      // Kewarganegaraan
      if (line.contains('KEWARGANEGARAAN')) {
        kewarganegaraan = _extractValue(line);
      }

      // Berlaku Hingga
      if (line.contains('BERLAKU HINGGA')) {
        berlakuHingga = _extractValue(line);
      }
    }

    // Calculate confidence based on how many fields were extracted
    int fieldsFound = 0;
    if (nik != null) fieldsFound++;
    if (nama != null) fieldsFound++;
    if (tanggalLahir != null) fieldsFound++;
    if (alamat != null) fieldsFound++;
    if (jenisKelamin != null) fieldsFound++;
    
    double confidence = fieldsFound / 5 * 100; // Based on 5 most important fields

    // Debug: Print extracted data
    print('🎯 Extracted Data:');
    print('  NIK: $nik');
    print('  Nama: $nama');
    print('  Tempat Lahir: $tempatLahir');
    print('  Tanggal Lahir: $tanggalLahir');
    print('  Jenis Kelamin: $jenisKelamin');
    print('  Confidence: ${confidence.toStringAsFixed(1)}%');

    // Post-processing: Validasi dan bersihkan data dari label
    print('🔍 Post-processing validation...');
    
    // Filter nama: tidak boleh mengandung kata kunci label
    if (nama != null) {
      final namaUpper = nama.toUpperCase();
      if (namaUpper.contains('TEMPAT') || namaUpper.contains('LAHIR') || 
          namaUpper.contains('TGL') || namaUpper == 'NAMA') {
        print('⚠️ Warning: Nama mengandung label, di-reset');
        nama = null;
      }
    }
    
    // Validasi nama tidak mengandung koma (kemungkinan tercampur dengan tempat lahir)
    if (nama != null && nama.contains(',')) {
      print('⚠️ Warning: Nama mengandung koma, kemungkinan tercampur dengan tempat lahir');
      final parts = nama.split(',').map((e) => e.trim()).toList();
      // Jika tempat lahir masih kosong, pindahkan ke tempat lahir
      if (tempatLahir == null && parts.length >= 2) {
        nama = parts[0]; // Ambil bagian pertama sebagai nama
        tempatLahir = parts[1]; // Bagian kedua sebagai tempat
        if (parts.length > 2 && tanggalLahir == null) {
          tanggalLahir = parts[2]; // Bagian ketiga sebagai tanggal
        }
        print('  ✅ Fixed - Nama: $nama, Tempat: $tempatLahir, Tanggal: $tanggalLahir');
      }
    }
    
    // Filter tempat lahir: tidak boleh mengandung kata kunci label atau sama dengan nama
    if (tempatLahir != null) {
      final tempatUpper = tempatLahir.toUpperCase();
      if (tempatUpper.contains('TEMPAT') || tempatUpper.contains('LAHIR') || 
          tempatUpper.contains('TGL') || tempatLahir == nama) {
        print('⚠️ Warning: Tempat lahir tidak valid (label atau sama dengan nama), di-reset');
        tempatLahir = null;
      }
    }
    
    // Jika tempat lahir sama dengan nama, reset tempat lahir
    if (tempatLahir != null && nama != null && tempatLahir.toUpperCase() == nama.toUpperCase()) {
      print('⚠️ Warning: Tempat lahir sama dengan nama, di-reset');
      tempatLahir = null;
    }

    return KTPOCRResult(
      nik: nik,
      nama: nama,
      tempatLahir: tempatLahir,
      tanggalLahir: tanggalLahir,
      jenisKelamin: jenisKelamin,
      golonganDarah: golonganDarah,
      alamat: alamat,
      rtRw: rtRw,
      kelDesa: kelDesa,
      kecamatan: kecamatan,
      agama: agama,
      statusPerkawinan: statusPerkawinan,
      pekerjaan: pekerjaan,
      kewarganegaraan: kewarganegaraan,
      berlakuHingga: berlakuHingga,
      confidence: confidence,
    );
  }

  /// Check if line is a NIK (16 digits)
  static bool _isNIK(String line) {
    final nikPattern = RegExp(r'\b\d{16}\b');
    return nikPattern.hasMatch(line);
  }

  /// Extract value after colon (:)
  static String _extractValue(String line) {
    if (line.contains(':')) {
      final parts = line.split(':');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return line.trim();
  }

  /// Check if string matches date pattern (DD-MM-YYYY or DD/MM/YYYY or DD.MM.YYYY)
  static bool _isDatePattern(String text) {
    final datePatterns = [
      RegExp(r'\d{1,2}[-/.]\d{1,2}[-/.]\d{4}'), // DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY
      RegExp(r'\d{1,2}\s+[A-Z]+\s+\d{4}'), // DD MONTH YYYY (e.g., 01 JANUARI 1990)
    ];
    
    for (final pattern in datePatterns) {
      if (pattern.hasMatch(text.toUpperCase())) {
        return true;
      }
    }
    return false;
  }
}