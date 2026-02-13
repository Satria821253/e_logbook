import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/api/trip_service.dart';
import '../../provider/user_provider.dart';
import 'upload_fuel_screen.dart';
import 'upload_ice_screen.dart';
import '../../utils/navigation_helper.dart';
import 'pre_tracking_simple.dart';

class PreTripFormV2 extends StatefulWidget {
  final int? tripId;
  final Map<String, dynamic>? tripData;

  const PreTripFormV2({Key? key, this.tripId, this.tripData}) : super(key: key);

  @override
  State<PreTripFormV2> createState() => _PreTripFormV2State();
}

class _PreTripFormV2State extends State<PreTripFormV2> {
  String? _userRole;
  bool _isLoading = true;

  // Crew uploads - STEP BY STEP
  String? _fuelFilePath;
  String? _iceFilePath;


  // Nahkoda uploads - STEP BY STEP
  String? _izinMelautPath;
  String? _dokumenKapalPath;
  String? _asuransiPath;
  bool _isLocked = false; // Status lock untuk nahkoda

  @override
  void initState() {
    super.initState();
    // Reset semua state ke null untuk mencegah tampilan state lama
    _fuelFilePath = null;
    _iceFilePath = null;
    _izinMelautPath = null;
    _dokumenKapalPath = null;
    _asuransiPath = null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserRole();
      await _loadTripOperationalData();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadTripOperationalData() async {
    if (widget.tripId == null) return;
    
    try {
      print('\n🔄 [LOAD] Fetching trip detail...');
      final response = await TripService.getTripDetail(widget.tripId!);
      
      if (response['success'] == true) {
        final tripData = response['data'];
        final perizinan = tripData?['perizinan'];
        
        final fuelDataList = perizinan?['fuelData'] as List?;
        final iceDataList = perizinan?['iceData'] as List?;
        final dokumen = perizinan?['dokumen'];
        
        print('📊 [LOAD] Fuel uploaded: ${fuelDataList != null && fuelDataList.isNotEmpty}');
        print('📊 [LOAD] Ice uploaded: ${iceDataList != null && iceDataList.isNotEmpty}');
        print('📊 [LOAD] Izin Melaut: ${dokumen?['izinMelaut'] == true}');
        print('📊 [LOAD] Dokumen Kapal: ${dokumen?['dokumenKapal'] == true}');
        print('📊 [LOAD] Asuransi: ${dokumen?['asuransi'] == true}');
        
        setState(() {
          if (fuelDataList != null && fuelDataList.isNotEmpty) _fuelFilePath = 'uploaded';
          if (iceDataList != null && iceDataList.isNotEmpty) _iceFilePath = 'uploaded';
          if (dokumen?['izinMelaut'] == true) _izinMelautPath = 'uploaded';
          if (dokumen?['dokumenKapal'] == true) _dokumenKapalPath = 'uploaded';
          if (dokumen?['asuransi'] == true) _asuransiPath = 'uploaded';
        });
        
        print('✅ [LOAD] Trip data loaded successfully');
      }
    } catch (e) {
      print('⚠️ [LOAD] Failed to load trip data: $e');
    }
  }

  Future<void> _loadUserRole() async {
    // Coba dari UserProvider dulu
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      setState(() {
        _userRole = userProvider.user!.role;
      });
      print('🔑 [LOAD ROLE] From UserProvider: $_userRole');
      return;
    }
    
    // Fallback ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    
    print('🔑 [LOAD ROLE] From SharedPreferences:');
    print('   user_data string: $userDataString');
    
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        final role = userData['role'];
        print('   Parsed role: $role');
        setState(() {
          _userRole = role;
        });
      } catch (e) {
        print('   ❌ Error parsing user_data: $e');
      }
    }
    
    print('   Final _userRole: $_userRole');
  }

  bool get _isNahkoda => _userRole?.toLowerCase() == 'nahkoda';
  bool get _isCrew => _userRole?.toLowerCase() == 'crew' || _userRole?.toLowerCase() == 'abk';

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
    // Jika masih loading data dari server, tampilkan loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('Persiapan Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          iconTheme: IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // DEBUG CONSOLE
    print('\n' + '='*60);
    print('🔍 DEBUG PRE-TRIP FORM V2');
    print('='*60);
    print('🆔 TRIP ID: ${widget.tripId}');  // <-- TRIP ID
    print('👤 POV: ${_isCrew ? "CREW" : _isNahkoda ? "NAHKODA" : "UNKNOWN"}');
    print('   Role: $_userRole');
    print('   isCrew: $_isCrew | isNahkoda: $_isNahkoda');
    print('\n📁 Upload Status:');
    print('   Fuel: ${_fuelFilePath != null ? "✓ Done" : "✗ Not Done"}');
    print('   Ice: ${_iceFilePath != null ? "✓ Done" : "✗ Not Done"}');
    print('   Izin: ${_izinMelautPath != null ? "✓ Done" : "✗ Not Done"}');
    print('   Dokumen: ${_dokumenKapalPath != null ? "✓ Done" : "✗ Not Done"}');
    print('   Asuransi: ${_asuransiPath != null ? "✓ Done" : "✗ Not Done"}');
    print('\n✅ Complete Status:');
    print('   Crew Complete: $_crewComplete');
    print('   Nahkoda Complete: $_nahkodaComplete');
    print('   Can Submit: $_canSubmit');
    if (_isNahkoda) {
      print('\n👁️ NAHKODA VIEW:');
      print('   Step 1-2 (Crew): ${_crewComplete ? "HIJAU" : "KUNING (Waiting)"}');
      print('   Step 3 (Izin): ${_crewComplete && !_izinMelautUploaded ? "KUNING" : "ABU"}');
    }
    if (_isCrew) {
      print('\n👁️ CREW VIEW:');
      print('   Step 1 (Fuel): ${!_fuelUploaded ? "BIRU" : "HIJAU"}');
      print('   Step 2 (Ice): ${_fuelUploaded && !_iceUploaded ? "BIRU" : !_fuelUploaded ? "ABU" : "HIJAU"}');
      print('   Step 3-5 (Nahkoda): ${_crewComplete && !_nahkodaComplete ? "KUNING (Waiting)" : _nahkodaComplete ? "HIJAU" : "ABU"}');
    }
    print('='*60 + '\n');
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Persiapan Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
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
    // Ambil data kapal dari tripData yang dikirim dari schedule
    final kapal = widget.tripData?['kapal'];
    final vesselName = kapal?['namaKapal'] ?? kapal?['nama'] ?? 'Trip';
    final vesselNumber = kapal?['nomorRegistrasi'] ?? '-';
    
    print('\n🚢 [TRIP HEADER] Vessel Data:');
    print('   Nama Kapal: $vesselName');
    print('   Nomor Registrasi: $vesselNumber');
    print('   Raw kapal data: $kapal');
    
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
                  vesselName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  vesselNumber,
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
    Color circleColor;
    IconData displayIcon;
    String statusDebug = '';
    
    if (done) {
      // HIJAU - sudah upload berhasil
      circleColor = Colors.green;
      displayIcon = Icons.check;
      statusDebug = 'HIJAU (Done)';
    } else if (_isCrew) {
      // LOGIKA CREW
      if (num == 1 && !_fuelUploaded) {
        // Step 1 Fuel: BIRU jika belum upload
        circleColor = Colors.blue;
        displayIcon = icon;
        statusDebug = 'BIRU (Step 1 Aktif)';
      } else if (num == 2 && _fuelUploaded && !_iceUploaded) {
        // Step 2 Ice: BIRU jika fuel sudah, ice belum
        circleColor = Colors.blue;
        displayIcon = icon;
        statusDebug = 'BIRU (Step 2 Aktif)';
      } else if (num == 3 && _crewComplete && !_izinMelautUploaded) {
        // Step 3 Izin: KUNING jika crew selesai dan nahkoda sedang upload izin
        circleColor = Colors.orange;
        displayIcon = Icons.hourglass_empty;
        statusDebug = 'KUNING (Nahkoda Upload Izin)';
      } else if (num == 4 && _izinMelautUploaded && !_dokumenKapalUploaded) {
        // Step 4 Dokumen: KUNING jika izin selesai, dokumen belum
        circleColor = Colors.orange;
        displayIcon = Icons.hourglass_empty;
        statusDebug = 'KUNING (Nahkoda Upload Dokumen)';
      } else if (num == 5 && _dokumenKapalUploaded && !_asuransiUploaded) {
        // Step 5 Asuransi: KUNING jika dokumen selesai, asuransi belum
        circleColor = Colors.orange;
        displayIcon = Icons.hourglass_empty;
        statusDebug = 'KUNING (Nahkoda Upload Asuransi)';
      } else {
        // Selain itu: ABU (locked)
        circleColor = Colors.grey[300]!;
        displayIcon = Icons.lock;
        statusDebug = 'ABU (Locked)';
      }
    } else if (_isNahkoda) {
      // LOGIKA NAHKODA
      if (num == 1 && !_fuelUploaded) {
        // Step 1 Fuel: KUNING jika crew sedang upload fuel
        circleColor = Colors.orange;
        displayIcon = Icons.hourglass_empty;
        statusDebug = 'KUNING (Crew Upload Fuel)';
      } else if (num == 2 && _fuelUploaded && !_iceUploaded) {
        // Step 2 Ice: KUNING jika fuel selesai, ice belum
        circleColor = Colors.orange;
        displayIcon = Icons.hourglass_empty;
        statusDebug = 'KUNING (Crew Upload Ice)';
      } else if (num == 3 && _crewComplete && !_izinMelautUploaded) {
        // Step 3 Izin: KUNING jika crew selesai dan izin belum
        circleColor = Colors.orange;
        displayIcon = Icons.edit;
        statusDebug = 'KUNING (Ready - Izin)';
      } else if (num == 4 && _izinMelautUploaded && !_dokumenKapalUploaded) {
        // Step 4 Dokumen: KUNING jika izin selesai dan dokumen belum
        circleColor = Colors.orange;
        displayIcon = Icons.edit;
        statusDebug = 'KUNING (Ready - Dokumen)';
      } else if (num == 5 && _dokumenKapalUploaded && !_asuransiUploaded) {
        // Step 5 Asuransi: KUNING jika dokumen selesai dan asuransi belum
        circleColor = Colors.orange;
        displayIcon = Icons.edit;
        statusDebug = 'KUNING (Ready - Asuransi)';
      } else {
        // Selain itu: ABU (locked)
        circleColor = Colors.grey[300]!;
        displayIcon = Icons.lock;
        statusDebug = 'ABU (Locked)';
      }
    } else {
      // Default: ABU
      circleColor = Colors.grey[300]!;
      displayIcon = Icons.lock;
      statusDebug = 'ABU (Default)';
    }
    
    // Debug print
    print('🎨 Step $num ($title): $statusDebug | done=$done, active=$active, locked=$locked');
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Icon(displayIcon, color: Colors.white, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool completed) {
    return Container(
      margin: EdgeInsets.only(left: 23, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: completed ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildCrewSection() {
    // Jika crew sudah complete, jangan tampilkan section ini
    if (_crewComplete) return SizedBox.shrink();
    
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

          _buildUploadCard('Data Bahan Bakar', Icons.local_gas_station, Colors.blue, _fuelUploaded, () => _navigateToFuelUpload(), _fuelFilePath, false),
          SizedBox(height: 16),
          _buildUploadCard('Data Es', Icons.ac_unit, Colors.cyan, _iceUploaded, () => _navigateToIceUpload(), _iceFilePath, !_fuelUploaded),
        ],
      ),
    );
  }

  Widget _buildNahkodaSection() {
    // Jika sudah lock, jangan tampilkan section ini
    if (_isLocked) return SizedBox.shrink();
    
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

          _buildUploadCard('Izin Melaut', Icons.sailing, Colors.green, _izinMelautPath != null, () => _pickDoc('izinMelaut'), _izinMelautPath, _isLocked),
          SizedBox(height: 16),
          _buildUploadCard('Dokumen Kapal', Icons.description, Colors.blue, _dokumenKapalPath != null, () => _pickDoc('dokumenKapal'), _dokumenKapalPath, _isLocked),
          SizedBox(height: 16),
          _buildUploadCard('Asuransi', Icons.security, Colors.purple, _asuransiPath != null, () => _pickDoc('asuransi'), _asuransiPath, _isLocked),
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
        child: Row(
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    // Nahkoda: Tombol LOCK PILIHAN jika semua file sudah dipilih tapi belum lock
    if (_isNahkoda && !_isLocked) {
      bool allFilesPicked = _izinMelautPath != null && _dokumenKapalPath != null && _asuransiPath != null;
      
      return Container(
        margin: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: allFilesPicked ? LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null,
          color: allFilesPicked ? null : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: allFilesPicked && !_isLoading ? _lockAndUpload : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 24, color: Colors.white),
                    SizedBox(width: 12),
                    Text('LOCK DATA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
        ),
      );
    }

    // Crew: Cek apakah nahkoda sudah dapat izin (status disetujui)
    if (_isCrew) {
      print('   ✅ Masuk kondisi CREW');
      if (_crewComplete) {
        print('   ✅ Crew Complete - Check if nahkoda got approval');
        
        // Jika nahkoda sudah dapat izin (semua dokumen nahkoda sudah upload), langsung navigasi
        if (_nahkodaComplete) {
          print('   ✅ Nahkoda complete - Auto navigate to waiting schedule');
          // Auto navigate setelah delay singkat
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) _submit();
          });
        }
        
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
                    Text(
                      _nahkodaComplete 
                          ? 'Nahkoda sudah menyelesaikan dokumen. Menuju waiting schedule...'
                          : 'Menunggu Nahkoda menyelesaikan dokumen',
                      style: TextStyle(fontSize: 13, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      
      // Crew bisa upload data BBM/Es
      bool hasCrewData = _fuelFilePath != null || _iceFilePath != null;
      print('   🔵 Crew belum complete - Show SIMPAN DATA button');
      print('   hasCrewData: $hasCrewData');
      return Container(
        margin: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: hasCrewData ? LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]) : null,
          color: hasCrewData ? null : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: hasCrewData && !_isLoading ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 24, color: Colors.white),
                    SizedBox(width: 12),
                    Text('SIMPAN DATA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
        ),
      );
    }

    // Nahkoda: tombol LANJUT jika sudah lock
    bool canProceed = _isNahkoda && _isLocked && _crewComplete;
    return Container(
      margin: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: canProceed ? LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]) : null,
        color: canProceed ? null : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: canProceed ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward, size: 24, color: Colors.white),
            SizedBox(width: 12),
            Text('LANJUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }



  Future<void> _navigateToFuelUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFuelScreen(tripId: widget.tripId!),
      ),
    );
    
    if (result == true) {
      setState(() => _fuelFilePath = 'uploaded');
      await _loadTripOperationalData();
    }
  }

  Future<void> _navigateToIceUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadIceScreen(tripId: widget.tripId!),
      ),
    );
    
    if (result == true) {
      setState(() => _iceFilePath = 'uploaded');
      await _loadTripOperationalData();
    }
  }

  Future<void> _pickDoc(String type) async {
    if (_isLocked) return; // Tidak bisa pilih file jika sudah lock
    
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

  Future<void> _lockAndUpload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Data'),
        content: Text('Pastikan semua dokumen sudah benar. Setelah dikunci, Anda tidak bisa mengubah pilihan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Ya, Lock')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dokumen terkunci. Klik LANJUT untuk melanjutkan.'), backgroundColor: Colors.green),
    );
  }

  Future<void> _submit() async {
    print('\n🔵 [SUBMIT] Button clicked');
    print('🔵 [SUBMIT] tripId: ${widget.tripId}');
    print('🔵 [SUBMIT] tripData keys: ${widget.tripData?.keys.toList()}');
    
    // Validasi tripId
    if (widget.tripId == null) {
      print('❌ [SUBMIT] Error: tripId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Trip ID tidak tersedia'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Pastikan tripData tidak null
    final tripData = widget.tripData ?? {};
    
    // Navigate ke PreTrackingScreen dengan membawa path dokumen
    NavigationHelper.pushNoTransition(
      context,
      PreTrackingScreenSimple(
        tripId: widget.tripId!,
        tripData: {
          ...tripData,
          'pendingDocuments': _isNahkoda ? {
            'izinMelaut': _izinMelautPath,
            'dokumenKapal': _dokumenKapalPath,
            'asuransi': _asuransiPath,
          } : null,
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}




