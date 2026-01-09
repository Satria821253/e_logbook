import 'package:e_logbook/models/attendance_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/services/attendance_service.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
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
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.height(context, mobile: 20, tablet: 24),
            horizontal: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
          ),
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
                size: ResponsiveHelper.width(context, mobile: 32, tablet: 36),
                color: isSelected ? color : Colors.grey.shade400,
              ),
              SizedBox(height: ResponsiveHelper.height(context, mobile: 8, tablet: 10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 16),
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
            title: Text(
              'Daftar Hadir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: ResponsiveHelper.font(context, mobile: 18, tablet: 20),
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
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.width(context, mobile: 20, tablet: 24),
                      0,
                      ResponsiveHelper.width(context, mobile: 20, tablet: 24),
                      ResponsiveHelper.height(context, mobile: 30, tablet: 36),
                    ),
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
                                  width: ResponsiveHelper.width(context, mobile: 140, tablet: 160),
                                  height: ResponsiveHelper.height(context, mobile: 140, tablet: 160),
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
                                      size: ResponsiveHelper.width(context, mobile: 90, tablet: 110),
                                      color: _hasMarkedToday ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: ResponsiveHelper.height(context, mobile: 20, tablet: 24)),
                        
                        Text(
                          _hasMarkedToday ? 'Sudah Absen' : 'Belum Absen',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, mobile: 28, tablet: 32),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveHelper.height(context, mobile: 8, tablet: 10)),
                        
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 16),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 20, tablet: 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 20, tablet: 24)),
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
                                  padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 10, tablet: 12)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4F9C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFF1B4F9C),
                                    size: ResponsiveHelper.width(context, mobile: 24, tablet: 28),
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                                Text(
                                  'Informasi ABK',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.font(context, mobile: 18, tablet: 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.height(context, mobile: 20, tablet: 24)),
                            _buildInfoRow(Icons.badge_outlined, 'Nama', user?.name ?? "-"),
                            SizedBox(height: ResponsiveHelper.height(context, mobile: 12, tablet: 16)),
                            _buildInfoRow(Icons.directions_boat_outlined, 'Kapal', user?.vesselName ?? "Belum terdaftar"),
                            SizedBox(height: ResponsiveHelper.height(context, mobile: 12, tablet: 16)),
                            _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal', '${now.day}/${now.month}/${now.year}'),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.height(context, mobile: 24, tablet: 28)),
                      
                      // Status Selection
                      if (!_hasMarkedToday) ...[
                        Text(
                          'Pilih Status Kehadiran',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, mobile: 18, tablet: 20),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 20)),
                        Row(
                          children: [
                            _buildStatusCard('hadir', 'Hadir', Icons.check_circle_rounded, Colors.green),
                            SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                            _buildStatusCard('izin', 'Izin', Icons.event_note_rounded, Colors.blue),
                            SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                            _buildStatusCard('sakit', 'Sakit', Icons.local_hospital_rounded, Colors.red),
                          ],
                        ),
                        
                        if (_selectedStatus != 'hadir') ...[
                          SizedBox(height: ResponsiveHelper.height(context, mobile: 20, tablet: 24)),
                          Container(
                            padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 20, tablet: 24)),
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
                                      size: ResponsiveHelper.width(context, mobile: 24, tablet: 28),
                                    ),
                                    SizedBox(width: ResponsiveHelper.width(context, mobile: 8, tablet: 12)),
                                    Text(
                                      'Alasan ${_selectedStatus == 'izin' ? 'Izin' : 'Sakit'}',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
                                        fontWeight: FontWeight.bold,
                                        color: _selectedStatus == 'izin' ? Colors.blue : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveHelper.height(context, mobile: 12, tablet: 16)),
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
                        
                        SizedBox(height: ResponsiveHelper.height(context, mobile: 24, tablet: 28)),
                        
                        // Mark Attendance Button
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveHelper.height(context, mobile: 56, tablet: 64),
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
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: ResponsiveHelper.width(context, mobile: 20, tablet: 24),
                                        height: ResponsiveHelper.height(context, mobile: 20, tablet: 24),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                                      Text(
                                        'Mencatat...',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: ResponsiveHelper.width(context, mobile: 24, tablet: 28)),
                                      SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                                      Text(
                                        'CATAT ${_selectedStatus.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
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
                          padding: EdgeInsets.all(ResponsiveHelper.width(context, mobile: 24, tablet: 28)),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: ResponsiveHelper.width(context, mobile: 60, tablet: 72),
                                color: Colors.green.shade600,
                              ),
                              SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 20)),
                              Text(
                                'Kehadiran Tercatat',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.font(context, mobile: 20, tablet: 24),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.height(context, mobile: 8, tablet: 12)),
                              Text(
                                'Terima kasih sudah melakukan absensi hari ini',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 16),
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: ResponsiveHelper.height(context, mobile: 20, tablet: 24)),
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
        Icon(icon, size: ResponsiveHelper.width(context, mobile: 20, tablet: 24), color: Colors.grey.shade600),
        SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 16),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}