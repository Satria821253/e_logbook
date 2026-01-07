import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFaqItem(
              'Bagaimana cara mengubah foto profil?',
              'Tekan ikon kamera pada foto profil Anda di halaman Profil. Pilih "Ambil Gambar" atau "Pilih dari Galeri".',
            ),
            _buildFaqItem(
              'Apakah aplikasi ini bisa berjalan offline?',
              'Ya, aplikasi menyimpan data secara lokal ketika tidak ada internet dan akan mengirimkannya otomatis saat sinyal tersedia kembali.',
            ),
            _buildFaqItem(
              'Bagaimana jika saya lupa password?',
              'Silakan hubungi admin dinas terkait atau koordinator lapangan untuk melakukan reset password akun Anda.',
            ),
            _buildFaqItem(
              'Siapa yang bisa melihat laporan saya?',
              'Laporan tangkapan Anda hanya dapat dilihat oleh Anda sendiri dan pihak berwenang dari dinas perikanan.',
            ),
            _buildFaqItem(
              'Kapan saya harus mengisi logbook?',
              'Sebaiknya logbook diisi segera setelah kegiatan penangkapan dilakukan agar data akurat.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4F9C),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
