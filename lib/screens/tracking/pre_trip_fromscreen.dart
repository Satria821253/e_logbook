import 'dart:async';
import 'package:e_logbook/screens/tracking/pre_tracking.dart';
import 'package:e_logbook/screens/tracking/crew_edit_screen.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lottie/lottie.dart';

/// Screen untuk form lengkap sebelum memulai trip
class PreTripFormScreen extends StatefulWidget {
  final Map<String, dynamic>? tripData;

  const PreTripFormScreen({super.key, this.tripData});

  @override
  State<PreTripFormScreen> createState() => _PreTripFormScreenState();
}

class _PreTripFormScreenState extends State<PreTripFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _vesselNameController = TextEditingController();
  final _vesselNumberController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _crewCountController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _fuelController = TextEditingController();
  final _iceStorageController = TextEditingController();
  final _notesController = TextEditingController();
  final _harborController = TextEditingController();

  // Selection values
  int _estimatedDuration = 1; // dalam hari
  DateTime? _departureDate; // From admin trip data
  DateTime? _estimatedReturnDate;

  // Harbor from admin data
  String? _departureHarbor;

  // Trip approval states
  bool _isSubmitting = false;
  bool _isWaitingApproval = false;
  bool _isApproved = false;

  // Crew details from edit
  Map<String, dynamic>? _crewDetails;

  // Tidak perlu API Key lagi - menggunakan Nominatim (OpenStreetMap) GRATIS!

  @override
  void initState() {
    super.initState();
    _loadVesselData();
    // Auto calculate return date on init if departure date is available
    if (_departureDate != null) {
      _estimatedReturnDate = _departureDate!.add(Duration(days: _estimatedDuration));
    }
  }

  void _loadVesselData() {
    // Load from trip data if available
    if (widget.tripData != null) {
      final tripData = widget.tripData!;
      _vesselNameController.text = tripData['vesselName'] ?? '';
      _vesselNumberController.text = tripData['vesselNumber'] ?? '';
      _crewCountController.text = tripData['crewCount']?.toString() ?? '';
      _departureHarbor = tripData['departureHarbor'];
      _estimatedDuration = tripData['estimatedDuration'] ?? 1;
      _departureDate = tripData['departureDate'] ?? DateTime.now(); // Use admin date or fallback to today
      _estimatedReturnDate = tripData['estimatedReturnDate'];
      _fuelController.text = tripData['fuelSupply']?.toString() ?? '';
      _iceStorageController.text = tripData['iceSupply']?.toString() ?? '';
      return;
    }

    // Fallback: use today's date if no admin data
    _departureDate = DateTime.now();

    // Fallback to user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user != null) {
      _vesselNameController.text = user.vesselName ?? '';
      _vesselNumberController.text = user.vesselNumber ?? '';
      _captainNameController.text = user.captainName ?? '';
      _crewCountController.text = user.crewCount?.toString() ?? '';
    }
  }

  void _submitTrip() async {
    if (_formKey.currentState!.validate()) {
      if (_departureHarbor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pelabuhan tidak tersedia')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Simulate API call to submit trip data
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _isSubmitting = false;
          _isWaitingApproval = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data trip berhasil dikirim, menunggu persetujuan admin',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Simulate admin approval after 5 seconds
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isWaitingApproval = false;
              _isApproved = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Trip disetujui! Anda dapat memulai trip sekarang',
                ),
                backgroundColor: Colors.blue,
              ),
            );
          }
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTrip() {
    final crewCount = int.tryParse(_crewCountController.text) ?? 0;
    if (crewCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah ABK tidak valid')));
      return;
    }

    // Navigate dengan data lengkap
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PreTrackingScreen(
          vesselName: _vesselNameController.text,
          vesselNumber: _vesselNumberController.text,
          captainName: _captainNameController.text,
          crewCount: crewCount,
          selectedHarbor: _departureHarbor!,
          departureTime: DateTime.now(),
          // Data tambahan
          estimatedDuration: _estimatedDuration,
          emergencyContact: _emergencyContactController.text,
          fuelAmount: double.tryParse(_fuelController.text) ?? 0,
          iceStorage: double.tryParse(_iceStorageController.text) ?? 0,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          harborCoordinates: null,
        ),
      ),
    );
  }

  void _editCrewCount() {
    final currentCount = int.tryParse(_crewCountController.text) ?? 0;
    if (currentCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah ABK tidak valid')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrewEditScreen(
          currentCrewCount: currentCount,
          adminCrewCount: widget.tripData?['crewCount'] ?? 8,
          existingCrewDetails: _crewDetails,
          onCrewUpdated: (newCount, crewDetails) {
            setState(() {
              _crewCountController.text = newCount.toString();
              _crewDetails = crewDetails;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vesselNameController.dispose();
    _vesselNumberController.dispose();
    _captainNameController.dispose();
    _crewCountController.dispose();
    _emergencyContactController.dispose();
    _fuelController.dispose();
    _iceStorageController.dispose();
    _notesController.dispose();
    _harborController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(top: sp(16), bottom: sp(16)),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: sp(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Persiapan Trip Melaut',
                            style: TextStyle(
                              fontSize: fs(22),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Lengkapi data sebelum berangkat',
                            style: TextStyle(
                              fontSize: fs(13),
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(sp(30)),
                      topRight: Radius.circular(sp(30)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(sp(24)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and title
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1B4F9C,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Lottie.asset(
                                    'assets/animations/PreTrip.json', // ubah sesuai nama file Anda
                                    width: fs(100),
                                    height: fs(100),
                                  ),
                                ),
                                SizedBox(height: sp(16)),
                                Text(
                                  'Formulir Pre-Trip',
                                  style: TextStyle(
                                    fontSize: fs(20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: sp(8)),
                                Text(
                                  'Data kapal & crew untuk tracking trip',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: fs(13),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: sp(32)),

                          // ===== SECTION 1: DATA KAPAL =====
                          _buildSectionHeader('1. Data Kapal', fs, sp),
                          SizedBox(height: sp(12)),

                          // Show vessel info if available
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final user = userProvider.user;
                              if (user?.vesselName != null) {
                                return Container(
                                  padding: EdgeInsets.all(sp(16)),
                                  margin: EdgeInsets.only(bottom: sp(16)),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(sp(12)),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.directions_boat,
                                            color: Colors.blue[700],
                                          ),
                                          SizedBox(width: sp(8)),
                                          Text(
                                            'Data Kapal Tersimpan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: fs(14),
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: sp(12)),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nama Kapal',
                                                  style: TextStyle(
                                                    fontSize: fs(11),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user!.vesselName!,
                                                  style: TextStyle(
                                                    fontSize: fs(13),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: sp(16)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nomor Kapal',
                                                  style: TextStyle(
                                                    fontSize: fs(11),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user.vesselNumber!,
                                                  style: TextStyle(
                                                    fontSize: fs(13),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: sp(8)),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nahkoda',
                                                  style: TextStyle(
                                                    fontSize: fs(11),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user.captainName!,
                                                  style: TextStyle(
                                                    fontSize: fs(13),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: sp(16)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Jumlah ABK',
                                                  style: TextStyle(
                                                    fontSize: fs(11),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  '${user.crewCount} orang',
                                                  style: TextStyle(
                                                    fontSize: fs(13),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),

                          _buildTextField(
                            controller: _vesselNameController,
                            label: 'Nama Kapal',
                            hint: 'Contoh: KM Bahari Jaya',
                            icon: Icons.directions_boat,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Wajib diisi' : null,
                            sp: sp,
                            fs: fs,
                            readOnly: true,
                          ),
                          SizedBox(height: sp(16)),

                          _buildTextField(
                            controller: _vesselNumberController,
                            label: 'Nomor Registrasi Kapal',
                            hint: 'Contoh: KP-12345-JKT',
                            icon: Icons.tag,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Wajib diisi' : null,
                            sp: sp,
                            fs: fs,
                            readOnly: true,
                          ),

                          SizedBox(height: sp(24)),

                          // ===== SECTION 2: DATA CREW =====
                          _buildSectionHeader('2. Data Crew', fs, sp),
                          SizedBox(height: sp(12)),

                          _buildTextField(
                            controller: _crewCountController,
                            label: 'Jumlah ABK',
                            hint: 'Contoh: 5',
                            icon: Icons.groups,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = int.tryParse(value!);
                              if (number == null || number < 1)
                                return 'Minimal 1 ABK';
                              return null;
                            },
                            sp: sp,
                            fs: fs,
                            readOnly: false,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1B4F9C),
                              ),
                              onPressed: () => _editCrewCount(),
                            ),
                          ),

                          // Show crew details if edited
                          if (_crewDetails != null) ...[
                            SizedBox(height: sp(16)),
                            Container(
                              padding: EdgeInsets.all(sp(16)),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(sp(12)),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: Colors.grey[700],
                                      ),
                                      SizedBox(width: sp(8)),
                                      Text(
                                        'Detail Kehadiran ABK',
                                        style: TextStyle(
                                          fontSize: fs(14),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: sp(12)),
                                  ...(_crewDetails!['crewList'] as List).map((
                                    crew,
                                  ) {
                                    final status = crew['status'];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: sp(4)),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == 'present'
                                                ? Icons.check_circle
                                                : status == 'izin'
                                                ? Icons.info
                                                : Icons.cancel,
                                            size: fs(16),
                                            color: status == 'present'
                                                ? Colors.green
                                                : status == 'izin'
                                                ? Colors.orange
                                                : Colors.red,
                                          ),
                                          SizedBox(width: sp(8)),
                                          Expanded(
                                            child: Text(
                                              crew['name'],
                                              style: TextStyle(
                                                fontSize: fs(12),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            status == 'present'
                                                ? 'Hadir'
                                                : status == 'izin'
                                                ? 'Izin ${crew['reason']}'
                                                : 'Tanpa Keterangan',
                                            style: TextStyle(
                                              fontSize: fs(11),
                                              color: status == 'present'
                                                  ? Colors.green[700]
                                                  : status == 'izin'
                                                  ? Colors.orange[700]
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: sp(24)),

                          // ===== SECTION 3: PELABUHAN =====
                          _buildSectionHeader(
                            '3. Pelabuhan Keberangkatan',
                            fs,
                            sp,
                          ),
                          SizedBox(height: sp(12)),

                          Container(
                            padding: EdgeInsets.all(sp(16)),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(sp(12)),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.anchor, color: Colors.blue[700]),
                                SizedBox(width: sp(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _departureHarbor ?? 'Belum ditentukan',
                                        style: TextStyle(
                                          fontSize: fs(16),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: sp(24)),
                          // ===== SECTION 4: ESTIMASI DURASI =====
                          _buildSectionHeader(
                            '4. Estimasi Durasi Trip',
                            fs,
                            sp,
                          ),
                          SizedBox(height: sp(12)),

                          // Tanggal Keberangkatan (From Admin)
                          _buildTextField(
                            controller: TextEditingController(text: _departureDate != null ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}' : ''),
                            label: 'Tanggal Keberangkatan',  
                            hint: 'Dari data admin',
                            icon: Icons.calendar_today,
                            validator: null,
                            sp: sp,
                            fs: fs,
                            readOnly: true,
                          ),
                          SizedBox(height: sp(16)),

                          // Waktu Keberangkatan 
                          _buildTextField(
                            controller: TextEditingController(text: _departureDate != null ? '${_departureDate!.hour.toString().padLeft(2, '0')}:${_departureDate!.minute.toString().padLeft(2, '0')}' : ''),
                            label: 'Waktu Keberangkatan',
                            hint: 'Dari data admin',
                            icon: Icons.access_time,
                            validator: null,
                            sp: sp,
                            fs: fs,
                            readOnly: true,
                          ),
                          SizedBox(height: sp(16)),

                          // Est Tanggal Kembali
                          _buildTextField(
                            controller: TextEditingController(text: _estimatedReturnDate != null ? '${_estimatedReturnDate!.day}/${_estimatedReturnDate!.month}/${_estimatedReturnDate!.year}' : ''),
                            label: 'Est Tanggal Kembali',
                            hint: 'Tap untuk pilih tanggal',
                            icon: Icons.event,
                            validator: null,
                            sp: sp,
                            fs: fs,
                            readOnly: true,
                            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            fillColor: Colors.white,
                            onTap: () async {
                              if (_departureDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tanggal keberangkatan belum tersedia dari admin'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _estimatedReturnDate ?? _departureDate!.add(Duration(days: _estimatedDuration)),
                                firstDate: _departureDate!,
                                lastDate: DateTime.now().add(Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(0xFF1B4F9C),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                if (picked.isBefore(_departureDate!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tanggal kembali tidak boleh kurang dari tanggal keberangkatan'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _estimatedReturnDate = picked;
                                  // Normalize both dates to midnight for accurate day calculation
                                  final departureNormalized = DateTime(_departureDate!.year, _departureDate!.month, _departureDate!.day);
                                  final returnNormalized = DateTime(picked.year, picked.month, picked.day);
                                  final newDuration = returnNormalized.difference(departureNormalized).inDays;
                                  _estimatedDuration = newDuration > 0 ? newDuration : 1;
                                  print('Debug: Departure normalized: $departureNormalized, Return normalized: $returnNormalized, Duration: $_estimatedDuration');
                                });
                              }
                            },
                          ),
                          SizedBox(height: sp(16)),

                          _buildDurationSlider(sp, fs),

                          SizedBox(height: sp(24)),

                          // ===== SECTION 5: PERSEDIAAN =====
                          _buildSectionHeader('5. Persediaan', fs, sp),
                          SizedBox(height: sp(12)),

                          _buildTextField(
                            controller: _fuelController,
                            label: 'Persediaan BBM (Liter)',
                            hint: 'Contoh: 500',
                            icon: Icons.local_gas_station,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = double.tryParse(value!);
                              if (number == null || number <= 0)
                                return 'Harus lebih dari 0';
                              return null;
                            },
                            sp: sp,
                            fs: fs,
                          ),
                          SizedBox(height: sp(16)),

                          _buildTextField(
                            controller: _iceStorageController,
                            label: 'Kapasitas Penyimpanan Es (Kg)',
                            hint: 'Contoh: 1000',
                            icon: Icons.ac_unit,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = double.tryParse(value!);
                              if (number == null || number <= 0)
                                return 'Harus lebih dari 0';
                              return null;
                            },
                            sp: sp,
                            fs: fs,
                          ),

                          SizedBox(height: sp(24)),

                          // Submit/Start button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting || _isWaitingApproval
                                  ? null
                                  : (_isApproved ? _startTrip : _submitTrip),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isApproved
                                    ? Colors.green
                                    : const Color(0xFF1B4F9C),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: sp(18)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(sp(12)),
                                ),
                                elevation: 4,
                              ),
                              child: _isSubmitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: fs(20),
                                          height: fs(20),
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: sp(12)),
                                        Text(
                                          'MENGIRIM...',
                                          style: TextStyle(
                                            fontSize: fs(16),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _isWaitingApproval
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: fs(20),
                                          height: fs(20),
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: sp(12)),
                                        Text(
                                          'MENUNGGU PERSETUJUAN ADMIN',
                                          style: TextStyle(
                                            fontSize: fs(14),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _isApproved
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.sailing, size: fs(24)),
                                        SizedBox(width: sp(12)),
                                        Text(
                                          'MULAI TRIP SEKARANG',
                                          style: TextStyle(
                                            fontSize: fs(16),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: fs(24)),
                                        SizedBox(width: sp(12)),
                                        Text(
                                          'KIRIM',
                                          style: TextStyle(
                                            fontSize: fs(16),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Status info when waiting for approval
                          if (_isWaitingApproval) ...[
                            SizedBox(height: sp(16)),
                            Container(
                              padding: EdgeInsets.all(sp(16)),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sp(12)),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange[700],
                                  ),
                                  SizedBox(width: sp(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Menunggu Persetujuan',
                                          style: TextStyle(
                                            fontSize: fs(14),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                        SizedBox(height: sp(4)),
                                        Text(
                                          'Data trip Anda sedang ditinjau oleh admin. Anda akan mendapat notifikasi setelah disetujui.',
                                          style: TextStyle(
                                            fontSize: fs(12),
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Success info when approved
                          if (_isApproved) ...[
                            SizedBox(height: sp(16)),
                            Container(
                              padding: EdgeInsets.all(sp(16)),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sp(12)),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                  ),
                                  SizedBox(width: sp(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip Disetujui!',
                                          style: TextStyle(
                                            fontSize: fs(14),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        SizedBox(height: sp(4)),
                                        Text(
                                          'Admin telah menyetujui trip Anda. Silakan mulai trip sekarang.',
                                          style: TextStyle(
                                            fontSize: fs(12),
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: sp(12)),

                          // Cancel button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: (_isSubmitting || _isWaitingApproval)
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[400]!),
                                padding: EdgeInsets.symmetric(vertical: sp(18)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(sp(12)),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: fs(16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: sp(24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp(12), vertical: sp(8)),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4F9C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(sp(8)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fs(16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4F9C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?)? validator,
    required double Function(double) sp,
    required double Function(double) fs,
    TextInputType? keyboardType,
    int? maxLines,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1B4F9C)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sp(12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sp(12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sp(12)),
          borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
        ),
        filled: true,
        fillColor: fillColor ?? (readOnly ? Colors.grey[100] : Colors.white),
        contentPadding: EdgeInsets.symmetric(
          horizontal: sp(16),
          vertical: sp(14),
        ),
      ),
    );
  }

  Widget _buildDurationSlider(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perkiraan Lama Trip',
                style: TextStyle(fontSize: fs(14), fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sp(12),
                  vertical: sp(6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4F9C),
                  borderRadius: BorderRadius.circular(sp(20)),
                ),
                child: Text(
                  '$_estimatedDuration Hari',
                  style: TextStyle(
                    fontSize: fs(14),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _estimatedDuration.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: Colors.grey[400],
            inactiveColor: Colors.grey[300],
            onChanged: null, // Disabled slider
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 hari',
                style: TextStyle(fontSize: fs(12), color: Colors.grey[600]),
              ),
              Text(
                '30 hari',
                style: TextStyle(fontSize: fs(12), color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
