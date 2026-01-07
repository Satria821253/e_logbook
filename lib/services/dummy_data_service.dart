import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_notification_service.dart';
import '../models/document_requirement_model.dart';

class DummyDataService {
  static Future<void> setupDummyData(String userEmail, String userRole) async {
    await _setupAdminNotifications(userEmail, userRole);
    await _setupDocumentRequirements(userEmail, userRole);
    print('Complex dummy data setup completed for user: $userEmail with role: $userRole');
  }

  static Future<void> _setupAdminNotifications(String userEmail, String userRole) async {
    // Clear existing data first
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_notifications');
    
    // Different notification based on role
    final notifications = [
      {
        'id': 'admin_001',
        'user_email': userEmail,
        'user_id': userEmail,
        'title': userRole == 'nahkoda' 
            ? '📋 Dokumen Nahkoda Belum Lengkap'
            : '📋 Dokumen Crew Belum Lengkap',
        'message': userRole == 'nahkoda'
            ? 'Ada dokumen nahkoda yang kurang lengkap nih, lengkapi sekarang untuk melanjutkan operasional kapal.'
            : 'Ada dokumen crew yang kurang lengkap nih, lengkapi sekarang untuk bisa bergabung dengan kapal.',
        'type': 'document_incomplete',
        'is_urgent': true,
        'is_read': false,
        'created_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      },
    ];

    for (var notification in notifications) {
      await AdminNotificationService.addAdminNotification(notification);
    }
  }

  static Future<void> _setupDocumentRequirements(String userEmail, String userRole) async {
    // Clear existing data first
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('document_requirements');
    
    if (userRole == 'nahkoda') {
      await _setupNahkodaDocuments(userEmail);
    } else {
      await _setupCrewDocuments(userEmail);
    }
  }

  // Documents for Nahkoda (8 documents)
  static Future<void> _setupNahkodaDocuments(String userEmail) async {
    final requirements = [
      DocumentRequirementModel(
        id: 'doc_req_nahkoda_001',
        userId: userEmail,
        userRole: 'nahkoda',
        title: '📋 Kelengkapan Dokumen Nahkoda (8 Dokumen Wajib)',
        description: 'Semua dokumen wajib yang harus dilengkapi sebelum memulai operasional sebagai nahkoda kapal',
        requiredDocuments: [
          // 1. KTP
          DocumentItem(
            name: 'KTP',
            description: 'Kartu Tanda Penduduk yang masih berlaku (scan kedua sisi, format PDF/JPG)',
            isRequired: true,
            isUploaded: false,
          ),
          // 2. Buku Pelaut
          DocumentItem(
            name: 'Buku Pelaut',
            description: 'Buku Pelaut yang masih berlaku sesuai kelas kapal yang akan dioperasikan',
            isRequired: true,
            isUploaded: false,
          ),
          // 3. Sertifikat Nahkoda
          DocumentItem(
            name: 'Sertifikat Nahkoda',
            description: 'Sertifikat Nahkoda sesuai jenis dan ukuran kapal (COC - Certificate of Competency)',
            isRequired: true,
            isUploaded: true,
            filePath: '/documents/sertifikat_nahkoda_${userEmail.split('@')[0]}.pdf',
            uploadedAt: DateTime.now().subtract(Duration(days: 3)),
          ),
          // 4. BST
          DocumentItem(
            name: 'BST (Basic Safety Training)',
            description: 'Sertifikat Basic Safety Training yang masih berlaku (Personal Survival, Fire Prevention, Elementary First Aid, Personal Safety)',
            isRequired: true,
            isUploaded: false,
          ),
          // 5. MCU
          DocumentItem(
            name: 'Surat Keterangan Sehat / MCU',
            description: 'Medical Check Up terbaru dari dokter yang berwenang (maksimal 1 tahun)',
            isRequired: true,
            isUploaded: true,
            filePath: '/documents/mcu_${userEmail.split('@')[0]}.pdf',
            uploadedAt: DateTime.now().subtract(Duration(days: 45)),
          ),
          // 6. SKCK
          DocumentItem(
            name: 'SKCK',
            description: 'Surat Keterangan Catatan Kepolisian yang masih berlaku (maksimal 6 bulan)',
            isRequired: true,
            isUploaded: false,
          ),
          // 7. Pas Foto
          DocumentItem(
            name: 'Pas Foto',
            description: 'Pas foto terbaru ukuran 4x6 cm dengan background putih, format JPG/PNG',
            isRequired: true,
            isUploaded: false,
          ),
          // 8. NPWP
          DocumentItem(
            name: 'NPWP',
            description: 'Nomor Pokok Wajib Pajak untuk keperluan administrasi gaji dan perpajakan',
            isRequired: true,
            isUploaded: false,
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(hours: 8)),
        dueDate: DateTime.now().add(Duration(days: 7)),
        isCompleted: false,
        isUrgent: true,
      ),
    ];

    for (var requirement in requirements) {
      await AdminNotificationService.addDocumentRequirement(requirement);
    }
  }

  // Documents for Crew (6 documents)
  static Future<void> _setupCrewDocuments(String userEmail) async {
    final requirements = [
      DocumentRequirementModel(
        id: 'doc_req_crew_001',
        userId: userEmail,
        userRole: 'crew',
        title: '📋 Kelengkapan Dokumen Crew (6 Dokumen Wajib)',
        description: 'Semua dokumen wajib yang harus dilengkapi sebelum bergabung sebagai crew kapal',
        requiredDocuments: [
          // 1. KTP
          DocumentItem(
            name: 'KTP',
            description: 'Kartu Tanda Penduduk yang masih berlaku (scan kedua sisi, format PDF/JPG)',
            isRequired: true,
            isUploaded: true,
            filePath: '/documents/ktp_${userEmail.split('@')[0]}.pdf',
            uploadedAt: DateTime.now().subtract(Duration(days: 2)),
          ),
          // 2. Buku Pelaut
          DocumentItem(
            name: 'Buku Pelaut',
            description: 'Buku Pelaut yang masih berlaku sesuai rating crew',
            isRequired: true,
            isUploaded: false,
          ),
          // 3. BST
          DocumentItem(
            name: 'BST (Basic Safety Training)',
            description: 'Sertifikat Basic Safety Training yang masih berlaku (Personal Survival, Fire Prevention, Elementary First Aid, Personal Safety)',
            isRequired: true,
            isUploaded: true,
            filePath: '/documents/bst_${userEmail.split('@')[0]}.pdf',
            uploadedAt: DateTime.now().subtract(Duration(days: 10)),
          ),
          // 4. MCU
          DocumentItem(
            name: 'Surat Keterangan Sehat / MCU',
            description: 'Medical Check Up terbaru dari dokter yang berwenang (maksimal 1 tahun)',
            isRequired: true,
            isUploaded: false,
          ),
          // 5. Pas Foto
          DocumentItem(
            name: 'Pas Foto',
            description: 'Pas foto terbaru ukuran 4x6 cm dengan background putih, format JPG/PNG',
            isRequired: true,
            isUploaded: false,
          ),
          // 6. SKCK
          DocumentItem(
            name: 'SKCK',
            description: 'Surat Keterangan Catatan Kepolisian yang masih berlaku (maksimal 6 bulan) - kadang diminta',
            isRequired: false, // Optional for crew
            isUploaded: false,
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(hours: 4)),
        dueDate: DateTime.now().add(Duration(days: 5)),
        isCompleted: false,
        isUrgent: true,
      ),
    ];

    for (var requirement in requirements) {
      await AdminNotificationService.addDocumentRequirement(requirement);
    }
  }
}