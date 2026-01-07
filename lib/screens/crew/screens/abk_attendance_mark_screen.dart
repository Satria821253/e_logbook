import 'package:e_logbook/models/attendance_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ABKAttendanceMarkScreen extends StatefulWidget {
  const ABKAttendanceMarkScreen({super.key});

  @override
  State<ABKAttendanceMarkScreen> createState() => _ABKAttendanceMarkScreenState();
}

class _ABKAttendanceMarkScreenState extends State<ABKAttendanceMarkScreen> with TickerProviderStateMixin {
  bool _isMarking = false;
  bool _hasMarkedToday = false;
  String _selectedStatus = 'hadir';
  final TextEditingController _reasonController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _checkInController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void dispose() {
    _reasonController.dispose();
    _pulseController.dispose();
    _checkInController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _checkInController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pulse animation for waiting state
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Check-in success animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkInController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkInController,
      curve: Curves.easeInOut,
    ));
    
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final records = await AttendanceService.getCrewAttendance(user.name);
    final today = DateTime.now();
    
    final todayRecord = records.where((r) => 
      r.tripDate.year == today.year &&
      r.tripDate.month == today.month &&
      r.tripDate.day == today.day
    ).isNotEmpty;

    setState(() {
      _hasMarkedToday = todayRecord;
    });
    
    // Start appropriate animation
    if (_hasMarkedToday) {
      _pulseController.stop();
      _checkInController.forward();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _markAttendance() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _isMarking = true);

    try {
      final attendance = AttendanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        crewName: user.name,
        vesselName: user.vesselName ?? 'Unknown',
        tripDate: DateTime.now(),
        status: _selectedStatus,
        reason: (_selectedStatus != 'hadir' && _reasonController.text.isNotEmpty) 
            ? _reasonController.text 
            : null,
        createdAt: DateTime.now(),
      );

      await AttendanceService.markAttendance(attendance);
      
      setState(() {
        _hasMarkedToday = true;
        _isMarking = false;
      });
      
      // Trigger check-in animation
      _pulseController.stop();
      _checkInController.reset();
      _checkInController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Status $_selectedStatus berhasil dicatat'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isMarking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Gagal mencatat kehadiran: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildStatusCard(String status, String label, IconData icon, Color color) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? color : Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final now = DateTime.now();
        final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Daftar Hadir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Card with Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Column(
                      children: [
                        // Status Indicator with Animation
                        AnimatedBuilder(
                          animation: _hasMarkedToday ? _checkInController : _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _hasMarkedToday ? _scaleAnimation.value : _pulseAnimation.value,
                              child: Transform.rotate(
                                angle: _hasMarkedToday ? _rotationAnimation.value * 0.1 : 0,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _hasMarkedToday 
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.2),
                                        blurRadius: _hasMarkedToday ? 25 : 20,
                                        offset: const Offset(0, 10),
                                        spreadRadius: _hasMarkedToday ? 5 : 0,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      _hasMarkedToday ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                      key: ValueKey(_hasMarkedToday),
                                      size: 90,
                                      color: _hasMarkedToday ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          _hasMarkedToday ? 'Sudah Absen' : 'Belum Absen',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4F9C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF1B4F9C),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Informasi ABK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(Icons.badge_outlined, 'Nama', user?.name ?? "-"),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.directions_boat_outlined, 'Kapal', user?.vesselName ?? "Belum terdaftar"),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal', '${now.day}/${now.month}/${now.year}'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status Selection
                      if (!_hasMarkedToday) ...[
                        const Text(
                          'Pilih Status Kehadiran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatusCard('hadir', 'Hadir', Icons.check_circle_rounded, Colors.green),
                            const SizedBox(width: 12),
                            _buildStatusCard('izin', 'Izin', Icons.event_note_rounded, Colors.blue),
                            const SizedBox(width: 12),
                            _buildStatusCard('sakit', 'Sakit', Icons.local_hospital_rounded, Colors.red),
                          ],
                        ),
                        
                        if (_selectedStatus != 'hadir') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: _selectedStatus == 'izin' ? Colors.blue : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Alasan ${_selectedStatus == 'izin' ? 'Izin' : 'Sakit'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedStatus == 'izin' ? Colors.blue : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _reasonController,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis alasan Anda di sini...',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _selectedStatus == 'izin' ? Colors.blue : Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Mark Attendance Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isMarking ? null : _markAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4F9C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: const Color(0xFF1B4F9C).withOpacity(0.3),
                            ),
                            child: _isMarking 
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Mencatat...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'CATAT ${_selectedStatus.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        // Already marked message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 60,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kehadiran Tercatat',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Terima kasih sudah melakukan absensi hari ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}