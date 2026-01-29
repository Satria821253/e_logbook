import 'dart:async';
import 'package:e_logbook/screens/tracking/pre_tracking.dart';
import 'package:e_logbook/screens/tracking/crew_edit_screen.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/widgets/custom_text_field.dart';
import 'package:e_logbook/widgets/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
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
    NavigationHelper.pushReplacementNoTransition(
      context,
      PreTrackingScreen(
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

    NavigationHelper.pushNoTransition(
      context,
      CrewEditScreen(
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
                padding: EdgeInsets.all(ResponsiveHelper.appBarPadding(context)),
                child: SizedBox(
                  height: ResponsiveHelper.appBarHeight(context),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: ResponsiveHelper.appBarIconSize(context),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 8)),
                      Expanded(
                        child: Text(
                          'Persiapan Trip Melaut',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.appBarTitleSize(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveHelper.borderRadius(context)),
                      topRight: Radius.circular(ResponsiveHelper.borderRadius(context)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveHelper.contentPadding(context)),
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
                                    'assets/animations/PreTrip.json',
                                    width: ResponsiveHelper.animationSize(context),
                                    height: ResponsiveHelper.animationSize(context),
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                                Text(
                                  'Formulir Pre-Trip',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.font(context, mobile: 20, tablet: 16),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.spacing(context, mobile: 8, tablet: 6)),
                                Text(
                                  'Data kapal & crew untuk tracking trip',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 11),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 32, tablet: 25)),

                          // ===== SECTION 1: DATA KAPAL =====
                          _buildSectionHeader('1. Data Kapal'),
                          const SizedBox(height: 10),

                          // Show vessel info if available
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final user = userProvider.user;
                              if (user?.vesselName != null) {
                                return Container(
                                  padding: EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                                  margin: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
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
                                          SizedBox(width: ResponsiveHelper.spacing(context, mobile: 8, tablet: 6)),
                                          Text(
                                            'Data Kapal Tersimpan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 11),
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
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
                                                    fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 9),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user!.vesselName!,
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 11),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nomor Kapal',
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 9),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user.vesselNumber!,
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 11),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: ResponsiveHelper.spacing(context, mobile: 8, tablet: 6)),
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
                                                    fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 9),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  user.captainName!,
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 11),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Jumlah ABK',
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 9),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  '${user.crewCount} orang',
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 11),
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

                          CustomTextField(
                            controller: _vesselNameController,
                            label: 'Nama Kapal',
                            hint: 'Contoh: KM Bahari Jaya',
                            icon: Icons.directions_boat,
                            readOnly: true,
                          ),
                          SizedBox(height: 16),

                          CustomTextField(
                            controller: _vesselNumberController,
                            label: 'Nomor Registrasi Kapal',
                            hint: 'Contoh: KP-12345-JKT',
                            icon: Icons.tag,
                            readOnly: true,
                          ),

                          SizedBox(height: 24),

                          // ===== SECTION 2: DATA CREW =====
                          _buildSectionHeader('2. Data Crew'),
                          SizedBox(height: 12),

                          CustomTextField(
                            controller: _crewCountController,
                            label: 'Jumlah ABK',
                            hint: 'Contoh: 5',
                            icon: Icons.groups,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = int.tryParse(value!);
                              if (number == null || number < 1) return 'Minimal 1 ABK';
                              return null;
                            },
                            readOnly: false,
                            suffixWidget: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1B4F9C),
                              ),
                              onPressed: () => _editCrewCount(),
                            ),
                          ),

                          // Show crew details if edited
                          if (_crewDetails != null) ...[
                            SizedBox(height: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                            Container(
                              padding: EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
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
                                      SizedBox(width: ResponsiveHelper.spacing(context, mobile: 8, tablet: 6)),
                                      Text(
                                        'Detail Kehadiran ABK',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 11),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                  ...(_crewDetails!['crewList'] as List).map((
                                    crew,
                                  ) {
                                    final status = crew['status'];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context, mobile: 4, tablet: 3)),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == 'present'
                                                ? Icons.check_circle
                                                : status == 'izin'
                                                ? Icons.info
                                                : Icons.cancel,
                                            size: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
                                            color: status == 'present'
                                                ? Colors.green
                                                : status == 'izin'
                                                ? Colors.orange
                                                : Colors.red,
                                          ),
                                          SizedBox(width: ResponsiveHelper.spacing(context, mobile: 8, tablet: 6)),
                                          Expanded(
                                            child: Text(
                                              crew['name'],
                                              style: TextStyle(
                                                fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 10),
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
                                              fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 9),
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

                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 19)),

                          // ===== SECTION 3: PELABUHAN =====
                          _buildSectionHeader('3. Pelabuhan Keberangkatan'),
                          SizedBox(height: 12),

                          Container(
                            padding: EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.anchor, color: Colors.blue[700]),
                                SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _departureHarbor ?? 'Belum ditentukan',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
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
                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 19)),
                          // ===== SECTION 4: ESTIMASI DURASI =====
                          _buildSectionHeader('4. Estimasi Durasi Trip'),
                          SizedBox(height: 12),

                          // Tanggal Keberangkatan (From Admin)
                          DateTimePickerField(
                            label: 'Tanggal Keberangkatan',
                            value: _departureDate != null 
                                ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
                                : 'Belum ditentukan',
                            icon: Icons.calendar_today,
                            onTap: () {},
                            isRequired: true,
                            hintText: 'Dari data admin',
                          ),
                          SizedBox(height: 16),

                          // Waktu Keberangkatan 
                          DateTimePickerField(
                            label: 'Waktu Keberangkatan',
                            value: _departureDate != null 
                                ? '${_departureDate!.hour.toString().padLeft(2, '0')}:${_departureDate!.minute.toString().padLeft(2, '0')}'
                                : 'Belum ditentukan',
                            icon: Icons.access_time,
                            onTap: () {},
                            isRequired: true,
                            hintText: 'Dari data admin',
                          ),
                          SizedBox(height: 16),

                          // Est Tanggal Kembali
                          DateTimePickerField(
                            label: 'Est Tanggal Kembali',
                            value: _estimatedReturnDate != null 
                                ? '${_estimatedReturnDate!.day}/${_estimatedReturnDate!.month}/${_estimatedReturnDate!.year}'
                                : 'Pilih tanggal',
                            icon: Icons.event,
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
                              final DateTime? picked = await CustomDatePicker.show(
                                context: context,
                                title: 'Pilih Tanggal Kembali',
                                initialDate: _estimatedReturnDate ?? _departureDate!.add(Duration(days: _estimatedDuration)),
                                firstDate: _departureDate!,
                                lastDate: DateTime.now().add(Duration(days: 365)),
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
                                  final departureNormalized = DateTime(_departureDate!.year, _departureDate!.month, _departureDate!.day);
                                  final returnNormalized = DateTime(picked.year, picked.month, picked.day);
                                  final newDuration = returnNormalized.difference(departureNormalized).inDays;
                                  _estimatedDuration = newDuration > 0 ? newDuration : 1;
                                });
                              }
                            },
                            isRequired: true,
                          ),
                          SizedBox(height: 16),

                          _buildDurationSlider(),

                          SizedBox(height: 24),

                          // ===== SECTION 5: PERSEDIAAN =====
                          _buildSectionHeader('5. Persediaan'),
                          SizedBox(height: 12),

                          CustomTextField(
                            controller: _fuelController,
                            label: 'Persediaan BBM (Liter)',
                            hint: 'Contoh: 500',
                            icon: Icons.local_gas_station,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = double.tryParse(value!);
                              if (number == null || number <= 0) return 'Harus lebih dari 0';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          CustomTextField(
                            controller: _iceStorageController,
                            label: 'Kapasitas Penyimpanan Es (Kg)',
                            hint: 'Contoh: 1000',
                            icon: Icons.ac_unit,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Wajib diisi';
                              final number = double.tryParse(value!);
                              if (number == null || number <= 0) return 'Harus lebih dari 0';
                              return null;
                            },
                          ),

                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 19)),

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
                                padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context, mobile: 18, tablet: 14)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                ),
                                elevation: 4,
                              ),
                              child: _isSubmitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: ResponsiveHelper.font(context, mobile: 20, tablet: 17),
                                          height: ResponsiveHelper.font(context, mobile: 20, tablet: 17),
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                        Text(
                                          'MENGIRIM...',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
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
                                          width: ResponsiveHelper.font(context, mobile: 20, tablet: 17),
                                          height: ResponsiveHelper.font(context, mobile: 20, tablet: 17),
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                        Text(
                                          'MENUNGGU PERSETUJUAN ADMIN',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 11),
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
                                        Icon(Icons.sailing, size: ResponsiveHelper.font(context, mobile: 24, tablet: 20)),
                                        SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                        Text(
                                          'MULAI TRIP SEKARANG',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
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
                                        Icon(Icons.send, size: ResponsiveHelper.font(context, mobile: 24, tablet: 20)),
                                        SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                        Text(
                                          'KIRIM',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
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
                            SizedBox(height: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                            Container(
                              padding: EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
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
                                  SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Menunggu Persetujuan',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 11),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveHelper.spacing(context, mobile: 4, tablet: 3)),
                                        Text(
                                          'Data trip Anda sedang ditinjau oleh admin. Anda akan mendapat notifikasi setelah disetujui.',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 10),
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
                            SizedBox(height: ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                            Container(
                              padding: EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 16, tablet: 12)),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
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
                                  SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip Disetujui!',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 11),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveHelper.spacing(context, mobile: 4, tablet: 3)),
                                        Text(
                                          'Admin telah menyetujui trip Anda. Silakan mulai trip sekarang.',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 10),
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

                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),

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
                                padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context, mobile: 18, tablet: 14)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, mobile: 12, tablet: 9)),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 19)),
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

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.width(context, mobile: 12, tablet: 10),
        vertical: ResponsiveHelper.height(context, mobile: 8, tablet: 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4F9C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 14),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4F9C),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDurationSlider() {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 16, tablet: 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.width(context, mobile: 12, tablet: 10),
                  vertical: ResponsiveHelper.height(context, mobile: 6, tablet: 5),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4F9C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_estimatedDuration Hari',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 12),
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
            onChanged: null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 hari',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 10),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '30 hari',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 10),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

