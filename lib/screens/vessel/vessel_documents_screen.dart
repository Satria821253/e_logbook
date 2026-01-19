import 'package:flutter/material.dart';
import '../../services/getAPi/vessel_service.dart';
import 'edit_fuel_screen.dart';

class VesselDocumentsScreen extends StatefulWidget {
  const VesselDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<VesselDocumentsScreen> createState() => _VesselDocumentsScreenState();
}

class _VesselDocumentsScreenState extends State<VesselDocumentsScreen> {
  Map<String, dynamic>? _documentsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final data = await VesselService().getVesselDocuments();
      print('📄 Documents data received:');
      print('   Sertifikat Jalan: ${(data['sertifikatJalan'] as List).length} items');
      print('   Data BBM: ${(data['dataBahanBakar'] as List).length} items');
      if ((data['dataBahanBakar'] as List).isNotEmpty) {
        print('   BBM List:');
        for (var bbm in (data['dataBahanBakar'] as List)) {
          print('     - ${bbm['jenisBahanBakar']}: ${bbm['jumlahLiter']} L');
        }
      }
      setState(() {
        _documentsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat dokumen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sertifikatJalan = _documentsData?['sertifikatJalan'] as List? ?? [];
    final dataBahanBakar = _documentsData?['dataBahanBakar'] as List? ?? [];
    final isEmpty = sertifikatJalan.isEmpty && dataBahanBakar.isEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Dokumen Kapal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('Belum ada dokumen kapal', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      if (sertifikatJalan.isNotEmpty) ...[
                        Text('Sertifikat Jalan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        ...sertifikatJalan.map((doc) => _buildSertifikatCard(doc)).toList(),
                        SizedBox(height: 24),
                      ],
                      if (dataBahanBakar.isNotEmpty) ...[
                        Text('Data Bahan Bakar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        ...dataBahanBakar.map((doc) => _buildBBMCard(doc)).toList(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSertifikatCard(Map<String, dynamic> doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc['nama'] ?? 'Sertifikat Jalan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Nomor', doc['nomorSertifikat'] ?? '-'),
                SizedBox(height: 12),
                _buildInfoRow('Tanggal Berlaku', doc['tanggalBerlaku'] ?? '-'),
                SizedBox(height: 12),
                _buildInfoRow('Upload', doc['uploadedAt'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBBMCard(Map<String, dynamic> doc) {
    print('📊 BBM Card data: $doc');
    print('🎯 BBM ID: ${doc['id']} (type: ${doc['id'].runtimeType})');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.local_gas_station, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc['jenisBahanBakar'] ?? 'BBM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditFuelScreen(fuelData: doc)),
                    );
                    if (result == true) {
                      print('🔄 Force refreshing documents after edit...');
                      await Future.delayed(Duration(seconds: 2));
                      await _loadDocuments();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Jumlah', '${doc['jumlahLiter'] ?? 0} Liter'),
                SizedBox(height: 12),
                _buildInfoRow('Total Harga', 'Rp ${doc['totalHarga'] ?? 0}'),
                SizedBox(height: 12),
                _buildInfoRow('Tanggal', doc['tanggalPengisian'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
