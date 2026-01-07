import 'package:flutter/material.dart';

enum CrewStatus { present, izin, tidakHadir }

class CrewEditScreen extends StatefulWidget {
  final int currentCrewCount;
  final int adminCrewCount;
  final Function(int, Map<String, dynamic>) onCrewUpdated;
  final Map<String, dynamic>? existingCrewDetails;

  const CrewEditScreen({
    super.key,
    required this.currentCrewCount,
    required this.adminCrewCount,
    required this.onCrewUpdated,
    this.existingCrewDetails,
  });

  @override
  State<CrewEditScreen> createState() => _CrewEditScreenState();
}

class _CrewEditScreenState extends State<CrewEditScreen> {
  late int _newCrewCount;
  bool _isSubmitting = false;

  // Dummy crew names from admin
  final List<String> _adminCrewList = [
    'Ahmad Suryadi',
    'Budi Santoso', 
    'Candra Wijaya',
    'Dedi Kurniawan',
    'Eko Prasetyo',
    'Fajar Ramadhan',
    'Gunawan Saputra',
    'Hendra Kusuma',
  ];

  List<CrewStatus> _crewStatus = [];
  List<TextEditingController> _reasonControllers = [];

  @override
  void initState() {
    super.initState();
    _newCrewCount = widget.currentCrewCount;
    
    // Initialize crew status and reason controllers
    _crewStatus = List.generate(widget.adminCrewCount, (index) => CrewStatus.present);
    _reasonControllers = List.generate(widget.adminCrewCount, (index) => TextEditingController());
    
    // Load existing crew details if available
    if (widget.existingCrewDetails != null) {
      final crewList = widget.existingCrewDetails!['crewList'] as List;
      for (int i = 0; i < crewList.length && i < _crewStatus.length; i++) {
        final crewData = crewList[i];
        final status = crewData['status'];
        if (status == 'present') {
          _crewStatus[i] = CrewStatus.present;
        } else if (status == 'izin') {
          _crewStatus[i] = CrewStatus.izin;
          _reasonControllers[i].text = crewData['reason'] ?? '';
        } else {
          _crewStatus[i] = CrewStatus.tidakHadir;
        }
      }
    } else {
      // Set absent crew based on current count
      for (int i = widget.currentCrewCount; i < widget.adminCrewCount; i++) {
        _crewStatus[i] = CrewStatus.tidakHadir;
      }
    }
    
    _updateCrewCount();
  }

  void _updateCrewCount() {
    _newCrewCount = _crewStatus.where((status) => status == CrewStatus.present).length;
  }

  void _submitCrewChanges() async {
    // Check if crew with izin status have reasons
    bool hasEmptyReason = false;
    for (int i = 0; i < _crewStatus.length; i++) {
      if (_crewStatus[i] == CrewStatus.izin && _reasonControllers[i].text.trim().isEmpty) {
        hasEmptyReason = true;
        break;
      }
    }
    
    if (hasEmptyReason) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan izin crew wajib diisi')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate saving locally
    await Future.delayed(const Duration(seconds: 1));

    // Prepare crew details
    final crewDetails = {
      'crewList': List.generate(_adminCrewList.length, (index) => {
        'name': _adminCrewList[index],
        'status': _crewStatus[index].toString().split('.').last,
        'reason': _crewStatus[index] == CrewStatus.izin ? _reasonControllers[index].text.trim() : '',
      }),
    };

    widget.onCrewUpdated(_newCrewCount, crewDetails);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data crew berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
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
                padding: EdgeInsets.all(sp(16)),
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
                            'Edit Jumlah ABK',
                            style: TextStyle(
                              fontSize: fs(22),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sesuaikan dengan kehadiran crew',
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

              // Content
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        Container(
                          padding: EdgeInsets.all(sp(16)),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(sp(12)),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ABK Ditentukan Admin:',
                                    style: TextStyle(
                                      fontSize: fs(14),
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  Text(
                                    '${widget.adminCrewCount} orang',
                                    style: TextStyle(
                                      fontSize: fs(14),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: sp(8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ABK Hadir:',
                                    style: TextStyle(
                                      fontSize: fs(16),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    '$_newCrewCount orang',
                                    style: TextStyle(
                                      fontSize: fs(16),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: sp(24)),

                        // Crew List
                        Text(
                          'Daftar ABK',
                          style: TextStyle(
                            fontSize: fs(18),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: sp(12)),

                        ...List.generate(_adminCrewList.length, (index) {
                          return Container(
                            margin: EdgeInsets.only(bottom: sp(8)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(sp(12)),
                              border: Border.all(
                                color: _crewStatus[index] == CrewStatus.present
                                    ? Colors.green.withOpacity(0.3)
                                    : _crewStatus[index] == CrewStatus.izin
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _crewStatus[index] == CrewStatus.present
                                        ? Colors.green.withOpacity(0.2)
                                        : _crewStatus[index] == CrewStatus.izin
                                            ? Colors.orange.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                    child: Icon(
                                      _crewStatus[index] == CrewStatus.present
                                          ? Icons.person
                                          : _crewStatus[index] == CrewStatus.izin
                                              ? Icons.person_outline
                                              : Icons.person_off,
                                      color: _crewStatus[index] == CrewStatus.present
                                          ? Colors.green[700]
                                          : _crewStatus[index] == CrewStatus.izin
                                              ? Colors.orange[700]
                                              : Colors.red[700],
                                    ),
                                  ),
                                  title: Text(
                                    _adminCrewList[index],
                                    style: TextStyle(
                                      fontSize: fs(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _crewStatus[index] == CrewStatus.present
                                        ? 'Hadir'
                                        : _crewStatus[index] == CrewStatus.izin
                                            ? 'Izin'
                                            : 'Tidak Hadir',
                                    style: TextStyle(
                                      fontSize: fs(12),
                                      color: _crewStatus[index] == CrewStatus.present
                                          ? Colors.green[600]
                                          : _crewStatus[index] == CrewStatus.izin
                                              ? Colors.orange[600]
                                              : Colors.red[600],
                                    ),
                                  ),
                                  trailing: PopupMenuButton<CrewStatus>(
                                    onSelected: (CrewStatus status) {
                                      setState(() {
                                        _crewStatus[index] = status;
                                        if (status != CrewStatus.izin) {
                                          _reasonControllers[index].clear();
                                        }
                                        _updateCrewCount();
                                      });
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: CrewStatus.present,
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, color: Colors.green[700]),
                                            SizedBox(width: sp(8)),
                                            const Text('Hadir'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: CrewStatus.izin,
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline, color: Colors.orange[700]),
                                            SizedBox(width: sp(8)),
                                            const Text('Izin'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: CrewStatus.tidakHadir,
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_off, color: Colors.red[700]),
                                            SizedBox(width: sp(8)),
                                            const Text('Tidak Hadir'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_crewStatus[index] == CrewStatus.izin) ...[
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(sp(16), 0, sp(16), sp(16)),
                                    child: TextFormField(
                                      controller: _reasonControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Alasan izin (contoh: sakit, urusan keluarga)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(sp(8)),
                                        ),
                                        filled: true,
                                        fillColor: Colors.orange[50],
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: sp(12),
                                          vertical: sp(8),
                                        ),
                                      ),
                                      style: TextStyle(fontSize: fs(12)),
                                    ),
                                  )
                                ],
                              ],
                            ),
                          );
                        }),

                        SizedBox(height: sp(24)),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitCrewChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4F9C),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: sp(18)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sp(12)),
                              ),
                            ),
                            child: _isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: fs(20),
                                        height: fs(20),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: sp(12)),
                                      Text(
                                        'Mengirim...',
                                        style: TextStyle(
                                          fontSize: fs(16),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send),
                                      SizedBox(width: sp(12)),
                                      Text(
                                        'Simpan Data Crew',
                                        style: TextStyle(
                                          fontSize: fs(16),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: sp(12)),

                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                      ],
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

  @override
  void dispose() {
    for (var controller in _reasonControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}