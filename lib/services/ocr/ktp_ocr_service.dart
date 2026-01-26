import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Model untuk hasil OCR KTP
class KTPOCRResult {
  final String? nik;
  final String? nama;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? alamat;
  final String? rtRw;
  final String? kelDesa;
  final String? kecamatan;
  final String? agama;
  final String? statusPerkawinan;
  final String? pekerjaan;
  final String? kewarganegaraan;
  final String? berlakuHingga;
  final String rawText;

  KTPOCRResult({
    this.nik,
    this.nama,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamat,
    this.rtRw,
    this.kelDesa,
    this.kecamatan,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
    this.kewarganegaraan,
    this.berlakuHingga,
    required this.rawText,
  });

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'rt_rw': rtRw,
      'kel_desa': kelDesa,
      'kecamatan': kecamatan,
      'agama': agama,
      'status_perkawinan': statusPerkawinan,
      'pekerjaan': pekerjaan,
      'kewarganegaraan': kewarganegaraan,
      'berlaku_hingga': berlakuHingga,
      'raw_text': rawText,
    };
  }
}

/// Service untuk OCR KTP menggunakan Google ML Kit
class KTPOCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Melakukan OCR pada gambar KTP
  static Future<KTPOCRResult> extractKTPData(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;
      
      return _parseKTPText(rawText);
    } catch (e) {
      throw Exception('Gagal melakukan OCR: $e');
    }
  }

  /// Parse text hasil OCR menjadi data terstruktur
  static KTPOCRResult _parseKTPText(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    String? nik, nama, tempatLahir, tanggalLahir, jenisKelamin, alamat;
    String? rtRw, kelDesa, kecamatan, agama, statusPerkawinan, pekerjaan;
    String? kewarganegaraan, berlakuHingga;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      final originalLine = lines[i];

      // NIK - 16 digit
      if (nik == null && _isNIK(originalLine)) {
        nik = _extractNumbers(originalLine);
      }

      // Nama
      if (line.contains('NAMA') && i + 1 < lines.length && !line.contains('PROVINSI')) {
        nama = lines[i + 1];
      }

      // Tempat/Tgl Lahir
      if (line.contains('TEMPAT') && line.contains('LAHIR') && i + 1 < lines.length) {
        final birthData = lines[i + 1];
        final parts = birthData.split(',');
        if (parts.length >= 2) {
          tempatLahir = parts[0].trim();
          tanggalLahir = parts[1].trim();
        } else {
          tempatLahir = birthData;
        }
      }

      // Jenis Kelamin
      if (line.contains('JENIS') && line.contains('KELAMIN') && i + 1 < lines.length) {
        jenisKelamin = lines[i + 1];
      }
      if (line.contains('LAKI-LAKI')) jenisKelamin = 'LAKI-LAKI';
      if (line.contains('PEREMPUAN')) jenisKelamin = 'PEREMPUAN';

      // Alamat
      if (line.contains('ALAMAT') && i + 1 < lines.length) {
        alamat = lines[i + 1];
      }

      // RT/RW
      if (line.contains('RT') && line.contains('RW') && i + 1 < lines.length) {
        rtRw = lines[i + 1];
      }

      // Kel/Desa
      if (line.contains('KEL') && line.contains('DESA') && i + 1 < lines.length) {
        kelDesa = lines[i + 1];
      }

      // Kecamatan
      if (line.contains('KECAMATAN') && i + 1 < lines.length) {
        kecamatan = lines[i + 1];
      }

      // Agama
      if (line.contains('AGAMA') && i + 1 < lines.length) {
        agama = lines[i + 1];
      }

      // Status Perkawinan
      if (line.contains('STATUS') && line.contains('PERKAWINAN') && i + 1 < lines.length) {
        statusPerkawinan = lines[i + 1];
      }
      if (line.contains('KAWIN') || line.contains('BELUM KAWIN')) {
        statusPerkawinan = originalLine;
      }

      // Pekerjaan
      if (line.contains('PEKERJAAN') && i + 1 < lines.length) {
        pekerjaan = lines[i + 1];
      }

      // Kewarganegaraan
      if (line.contains('KEWARGANEGARAAN') && i + 1 < lines.length) {
        kewarganegaraan = lines[i + 1];
      }
      if (line.contains('WNI')) kewarganegaraan = 'WNI';

      // Berlaku Hingga
      if (line.contains('BERLAKU') && line.contains('HINGGA') && i + 1 < lines.length) {
        berlakuHingga = lines[i + 1];
      }
      if (line.contains('SEUMUR HIDUP')) berlakuHingga = 'SEUMUR HIDUP';
    }

    return KTPOCRResult(
      nik: nik,
      nama: nama,
      tempatLahir: tempatLahir,
      tanggalLahir: tanggalLahir,
      jenisKelamin: jenisKelamin,
      alamat: alamat,
      rtRw: rtRw,
      kelDesa: kelDesa,
      kecamatan: kecamatan,
      agama: agama,
      statusPerkawinan: statusPerkawinan,
      pekerjaan: pekerjaan,
      kewarganegaraan: kewarganegaraan,
      berlakuHingga: berlakuHingga,
      rawText: text,
    );
  }

  static bool _isNIK(String text) {
    final numbers = _extractNumbers(text);
    return numbers.length == 16;
  }

  static String _extractNumbers(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
