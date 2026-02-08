import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api/trip_service.dart';
import 'waiting_approval_screen.dart';
import '../../utils/navigation_helper.dart';

class PreTripFormV2 extends StatefulWidget {
  final int? tripId;
  final Map<String, dynamic>? tripData;

  const PreTripFormV2({Key? key, this.tripId, this.tripData}) : super(key: key);

  @override
  State<PreTripFormV2> createState() => _PreTripFormV2State();
}

class _PreTripFormV2State extends State<PreTripFormV2> {
  String? _userRole;
  bool _isLoading = false;

  // Crew uploads - STEP BY STEP
  String? _fuelFilePath;
  String? _iceFilePath;
  final _fuelAmountController = TextEditingController();
  final _fuelPriceController = TextEditingController();
  final _iceAmountController = TextEditingController();
  final _icePriceController = TextEditingController();

  // Nahkoda uploads - STEP BY STEP
  String? _izinMelautPath;
  String? _dokumenKapalPath;
  String? _asuransiPath;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  bool get _isNahkoda => _userRole == 'nahkoda';
  bool get _isCrew => _userRole == 'crew' || _userRole == 'abk';

  // ONE BY ONE checks
  bool get _fuelUploaded => _fuelFilePath != null;
  bool get _iceUploaded => _iceFilePath != null;
  bool get _izinMelautUploaded => _izinMelautPath != null;
  bool get _dokumenKapalUploaded => _dokumenKapalPath != null;
  bool get _asuransiUploaded => _asuransiPath != null;

  bool get _crewComplete => _fuelUploaded && _iceUploaded;
  bool get _nahkodaComplete => _izinMelautUploaded && _dokumenKapalUploaded && _asuransiUploaded;
  bool get _canSubmit => _crewComplete && _nahkodaComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Persiapan Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTripHeader(),
            _buildProgressTracker(),
            if (_isCrew) _buildCrewSection(),
            if (_isNahkoda) _buildNahkodaSection(),
            _buildSubmitButton(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.sailing, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tripData?['vesselName'] ?? 'Trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  widget.tripData?['vesselNumber'] ?? '-',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: Color(0xFF1B4F9C), size: 24),
              SizedBox(width: 12),
              Text('Progress Persiapan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ],
          ),
          SizedBox(height: 24),

          _buildStep(1, 'Upload BBM', 'Crew', _fuelUploaded, !_fuelUploaded && _isCrew, false, Icons.local_gas_station, Colors.blue),
          _buildConnector(_fuelUploaded),
          _buildStep(2, 'Upload Es', 'Crew', _iceUploaded, !_iceUploaded && _isCrew && _fuelUploaded, !_fuelUploaded, Icons.ac_unit, Colors.cyan),
          _buildConnector(_iceUploaded),
          _buildStep(3, 'Izin Melaut', 'Nahkoda', _izinMelautUploaded, !_izinMelautUploaded && _isNahkoda && _crewComplete, !_crewComplete, Icons.sailing, Colors.green),
          _buildConnector(_izinMelautUploaded),
          _buildStep(4, 'Dokumen Kapal', 'Nahkoda', _dokumenKapalUploaded, !_dokumenKapalUploaded && _isNahkoda && _izinMelautUploaded, !_izinMelautUploaded, Icons.description, Colors.orange),
          _buildConnector(_dokumenKapalUploaded),
          _buildStep(5, 'Asuransi', 'Nahkoda', _asuransiUploaded, !_asuransiUploaded && _isNahkoda && _dokumenKapalUploaded, !_dokumenKapalUploaded, Icons.security, Colors.purple),
          _buildConnector(_canSubmit),
          _buildStep(6, 'Siap Berangkat', 'Trip', _canSubmit, false, !_canSubmit, Icons.check_circle, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String title, String subtitle, bool done, bool active, bool locked, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: done ? Colors.green : active ? color : locked ? Colors.grey[300] : Colors.grey[200],
            shape: BoxShape.circle,
            boxShadow: done || active ? [BoxShadow(color: (done ? Colors.green : color).withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: Icon(done ? Icons.check : locked ? Icons.lock : icon, color: Colors.white, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: done || active ? Colors.black87 : Colors.grey[500])),
              Text(subtitle, style: TextStyle(fontSize: 13, color: done || active ? Colors.grey[600] : Colors.grey[400])),
            ],
          ),
        ),
        if (done)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
      ],
    );
  }

  Widget _buildConnector(bool done) {
    return Container(
      margin: EdgeInsets.only(left: 24, top: 8, bottom: 8),
      width: 2,
      height: 30,
      color: done ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildCrewSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.assignment_ind, color: Colors.blue, size: 24),
              ),
              SizedBox(width: 12),
              Text('Tugas Crew', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ],
          ),
          SizedBox(height: 20),

          _buildUploadCard('Data Bahan Bakar', Icons.local_gas_station, Colors.blue, _fuelUploaded, () => _showFuelDialog(), _fuelFilePath, false),
          SizedBox(height: 16),
          _buildUploadCard('Data Es', Icons.ac_unit, Colors.cyan, _iceUploaded, () => _showIceDialog(), _iceFilePath, !_fuelUploaded),
        ],
      ),
    );
  }

  Widget _buildNahkodaSection() {
    if (!_crewComplete && _isNahkoda) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menunggu Crew', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                  SizedBox(height: 4),
                  Text('Crew sedang upload BBM & Es', style: TextStyle(fontSize: 13, color: Colors.orange[700])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.admin_panel_settings, color: Colors.orange, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Tugas Nahkoda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.email, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Surat perizinan dikirim admin via email', style: TextStyle(fontSize: 12, color: Colors.blue[800]))),
              ],
            ),
          ),
          SizedBox(height: 20),

          _buildUploadCard('Izin Melaut', Icons.sailing, Colors.green, _izinMelautUploaded, () => _pickDoc('izinMelaut'), _izinMelautPath, false),
          SizedBox(height: 16),
          _buildUploadCard('Dokumen Kapal', Icons.description, Colors.blue, _dokumenKapalUploaded, () => _pickDoc('dokumenKapal'), _dokumenKapalPath, !_izinMelautUploaded),
          SizedBox(height: 16),
          _buildUploadCard('Asuransi', Icons.security, Colors.purple, _asuransiUploaded, () => _pickDoc('asuransi'), _asuransiPath, !_dokumenKapalUploaded),
        ],
      ),
    );
  }

  Widget _buildUploadCard(String title, IconData icon, Color color, bool done, VoidCallback onTap, String? path, bool locked) {
    return InkWell(
      onTap: done || locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: locked ? Colors.grey[100] : done ? Colors.green.withOpacity(0.1) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: locked ? Colors.grey[300]! : done ? Colors.green : color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: locked ? Colors.grey[300] : done ? Colors.green : color, borderRadius: BorderRadius.circular(10)),
                  child: Icon(locked ? Icons.lock : done ? Icons.check : icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: locked ? Colors.grey[500] : done ? Colors.green[800] : Colors.grey[800]))),
                Icon(locked ? Icons.lock : done ? Icons.check_circle : Icons.upload_file, color: locked ? Colors.grey[400] : done ? Colors.green : color, size: 24),
              ],
            ),
            if (locked) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(child: Text('Selesaikan upload sebelumnya', style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                  ],
                ),
              ),
            ],
            if (done && path != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(child: Text(path.split('/').last, style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    // Crew tidak bisa tekan KIRIM, hanya Nahkoda
    if (_isCrew) {
      if (_crewComplete) {
        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Selesai!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    SizedBox(height: 4),
                    Text('Menunggu Nahkoda menyelesaikan dokumen dan mengirim', style: TextStyle(fontSize: 13, color: Colors.green[700])),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox.shrink();
    }

    // Nahkoda bisa tekan KIRIM
    return Container(
      margin: EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit && !_isLoading && _isNahkoda ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canSubmit ? Colors.green : Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 24),
                  SizedBox(width: 12),
                  Text('KIRIM & MULAI TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  void _showFuelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Data BBM'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _fuelAmountController, decoration: InputDecoration(labelText: 'Jumlah (Liter)'), keyboardType: TextInputType.number),
            TextField(controller: _fuelPriceController, decoration: InputDecoration(labelText: 'Harga/Liter (Rp)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
              if (result != null) {
                setState(() => _fuelFilePath = result.files.single.path);
                Navigator.pop(context);
              }
            },
            child: Text('Upload Bukti'),
          ),
        ],
      ),
    );
  }

  void _showIceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Data Es'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _iceAmountController, decoration: InputDecoration(labelText: 'Jumlah (Kg)'), keyboardType: TextInputType.number),
            TextField(controller: _icePriceController, decoration: InputDecoration(labelText: 'Harga/Kg (Rp)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
              if (result != null) {
                setState(() => _iceFilePath = result.files.single.path);
                Navigator.pop(context);
              }
            },
            child: Text('Upload Bukti'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDoc(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ukuran file maksimal 10MB'), backgroundColor: Colors.red));
          return;
        }
        setState(() {
          if (type == 'izinMelaut') _izinMelautPath = file.path;
          if (type == 'dokumenKapal') _dokumenKapalPath = file.path;
          if (type == 'asuransi') _asuransiPath = file.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isCrew && widget.tripId != null) {
        if (_fuelFilePath != null) {
          await TripService.uploadFuelData(
            tripId: widget.tripId!,
            jenisBahanBakar: 'Solar',
            jumlahLiter: double.parse(_fuelAmountController.text),
            hargaPerLiter: double.parse(_fuelPriceController.text),
            totalHarga: double.parse(_fuelAmountController.text) * double.parse(_fuelPriceController.text),
            tanggalPengisian: DateTime.now().toIso8601String(),
            buktiFilePath: _fuelFilePath,
          );
        }
        if (_iceFilePath != null) {
          await TripService.uploadIceData(
            tripId: widget.tripId!,
            jenisEs: 'Es Balok',
            jumlahKg: double.parse(_iceAmountController.text),
            hargaPerKg: double.parse(_icePriceController.text),
            totalHarga: double.parse(_iceAmountController.text) * double.parse(_icePriceController.text),
            tanggalPembelian: DateTime.now().toIso8601String(),
            buktiFilePath: _iceFilePath,
          );
        }
      }

      if (_isNahkoda && widget.tripId != null) {
        if (_izinMelautPath != null) await TripService.uploadTripDocument(tripId: widget.tripId!, jenisDokumen: 'izinMelaut', filePath: _izinMelautPath!);
        if (_dokumenKapalPath != null) await TripService.uploadTripDocument(tripId: widget.tripId!, jenisDokumen: 'dokumenKapal', filePath: _dokumenKapalPath!);
        if (_asuransiPath != null) await TripService.uploadTripDocument(tripId: widget.tripId!, jenisDokumen: 'asuransi', filePath: _asuransiPath!);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua data berhasil dikirim!'), backgroundColor: Colors.green));

      // Navigate to waiting approval screen for both Nahkoda and Crew
      NavigationHelper.pushReplacementNoTransition(
        context,
        WaitingApprovalScreen(
          tripData: {
            'tripId': widget.tripId,
            'vesselName': widget.tripData?['vesselName'] ?? '',
            'vesselNumber': widget.tripData?['vesselNumber'] ?? '',
            'captainName': widget.tripData?['captainName'] ?? '',
            'crewCount': widget.tripData?['crewCount'] ?? 0,
            'departureHarbor': widget.tripData?['departureHarbor'] ?? '',
            'departureDate': widget.tripData?['departureDate'] ?? DateTime.now(),
            'estimatedDuration': widget.tripData?['estimatedDuration'] ?? 1,
            'emergencyContact': widget.tripData?['emergencyContact'] ?? '',
            'fuelAmount': widget.tripData?['fuelAmount'] ?? 0.0,
            'iceStorage': widget.tripData?['iceStorage'] ?? 0.0,
            'notes': widget.tripData?['notes'],
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fuelAmountController.dispose();
    _fuelPriceController.dispose();
    _iceAmountController.dispose();
    _icePriceController.dispose();
    super.dispose();
  }
}
