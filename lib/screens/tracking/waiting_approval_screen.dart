import 'package:e_logbook/screens/tracking/waiting_schedule_screen.dart';
import 'package:e_logbook/services/api/trip_service.dart';
import 'package:e_logbook/services/nitification/notification_service.dart';
import 'package:e_logbook/services/nitification/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../provider/user_provider.dart';

class PollingConfig {
  static const Duration initialInterval = Duration(seconds: 5);
  static const Duration maxInterval = Duration(seconds: 30);
  static const int maxRetries = 20;
  static const double zoneRadius = 50.0;
  static const List<String> approvedStatuses = ['disetujui', 'aktif'];
}

enum ApprovalState { loading, polling, approved, error, timeout }

class WaitingApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const WaitingApprovalScreen({Key? key, required this.tripData}) : super(key: key);

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  ApprovalState _state = ApprovalState.loading;
  Timer? _pollTimer;
  String? _userRole;
  int _retryCount = 0;
  int _pollCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserRole();
    _startPolling();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('role') ?? widget.tripData['role'];
  }

  Duration _getNextInterval() {
    final seconds = min(
      PollingConfig.initialInterval.inSeconds * pow(1.5, _retryCount).toInt(),
      PollingConfig.maxInterval.inSeconds,
    );
    return Duration(seconds: seconds);
  }

  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void _startPolling() {
    _pollCount = 0;
    _retryCount = 0;
    setState(() {
      _state = ApprovalState.polling;
      _errorMessage = null;
    });
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    
    if (_pollCount >= PollingConfig.maxRetries) {
      if (mounted) {
        setState(() {
          _state = ApprovalState.timeout;
          _errorMessage = 'Waktu tunggu habis. Silakan coba lagi.';
        });
      }
      return;
    }

    final interval = _getNextInterval();
    _pollTimer = Timer(interval, _checkApprovalStatus);
  }

  Future<void> _checkApprovalStatus() async {
    if (!mounted) return;

    _pollCount++;

    if (!await _hasConnection()) {
      _retryCount++;
      if (mounted) {
        setState(() {
          _state = ApprovalState.error;
          _errorMessage = 'Tidak ada koneksi internet';
        });
      }
      _scheduleNextPoll();
      return;
    }

    try {
      final tripId = widget.tripData['tripId'];
      if (tripId == null) {
        if (mounted) {
          setState(() {
            _state = ApprovalState.error;
            _errorMessage = 'Trip ID tidak valid';
          });
        }
        return;
      }

      final response = await TripService.getTripDetail(tripId);

      if (!mounted) return;

      if (response['success'] == true) {
        final status = response['data']?['status']?.toString().toLowerCase();

        if (PollingConfig.approvedStatuses.contains(status)) {
          setState(() => _state = ApprovalState.approved);
          _pollTimer?.cancel();
          await _sendApprovalNotification(response['data']);
          _navigateToWaitingSchedule(response['data']);
        } else {
          _retryCount = 0;
          setState(() => _state = ApprovalState.polling);
          _scheduleNextPoll();
        }
      } else {
        _retryCount++;
        setState(() {
          _state = ApprovalState.error;
          _errorMessage = 'Gagal memeriksa status';
        });
        _scheduleNextPoll();
      }
    } catch (e) {
      _retryCount++;
      if (mounted) {
        setState(() {
          _state = ApprovalState.error;
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
      _scheduleNextPoll();
    }
  }

  Future<void> _sendApprovalNotification(Map<String, dynamic> tripData) async {
    try {
      final kapal = tripData['kapal'] ?? {};
      final vesselName = kapal['namaKapal'] ?? widget.tripData['vesselName'] ?? 'Kapal';

      DateTime departureTime = DateTime.now();
      if (tripData['waktuMulai'] != null) {
        departureTime = DateTime.parse(tripData['waktuMulai']);
      } else if (tripData['tanggalBerangkat'] != null) {
        departureTime = DateTime.parse(tripData['tanggalBerangkat']);
      }

      final duration = departureTime.difference(DateTime.now());
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      String timeText;
      if (hours > 24) {
        timeText = '${duration.inDays} hari lagi';
      } else if (hours > 0) {
        timeText = '$hours jam $minutes menit lagi';
      } else {
        timeText = '$minutes menit lagi';
      }

      await NotificationService.addTripNotification(
        tripId: widget.tripData['tripId'].toString(),
        vesselName: vesselName,
        departureTime: departureTime,
        message: 'Trip Anda telah aktif! Kapal $vesselName akan berangkat $timeText',
      );

      await LocalNotificationService.showTripApprovedNotification(
        vesselName: vesselName,
        departureTime: departureTime,
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  void _navigateToHome() {
    _pollTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _navigateToWaitingSchedule(Map<String, dynamic> apiTripData) async {
    _pollTimer?.cancel();
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    final role = _userRole ?? prefs.getString('role') ?? widget.tripData['role'];
    final userName = userProvider.user?.name ?? prefs.getString('name') ?? '';
    final finalUserRole = (role?.toString().toLowerCase().contains('nahkoda') ?? false) ? 'Nahkoda' : 'ABK';

    double totalFuel = 0;
    double totalIce = 0;
    DateTime? actualDepartureTime;
    int? actualDuration;
    DateTime? estimatedReturnDate;

    final perizinan = apiTripData['perizinan'] ?? {};

    final fuelDataList = perizinan['fuelData'] as List? ?? [];
    for (var fuel in fuelDataList) {
      totalFuel += (fuel['jumlahLiter'] ?? 0).toDouble();
    }

    final iceDataList = perizinan['iceData'] as List? ?? [];
    for (var ice in iceDataList) {
      totalIce += (ice['jumlahKg'] ?? 0).toDouble();
    }

    if (apiTripData['waktuMulai'] != null) {
      actualDepartureTime = DateTime.parse(apiTripData['waktuMulai']);
    } else if (apiTripData['tanggalBerangkat'] != null) {
      actualDepartureTime = DateTime.parse(apiTripData['tanggalBerangkat']);
    }

    if (apiTripData['estimasiPulang'] != null) {
      estimatedReturnDate = DateTime.parse(apiTripData['estimasiPulang']);
    }

    actualDuration = apiTripData['durasi'];

    final fuelAmount = totalFuel > 0 ? totalFuel : (widget.tripData['fuelAmount'] ?? 0.0).toDouble();
    final iceStorage = totalIce > 0 ? totalIce : (widget.tripData['iceStorage'] ?? 0.0).toDouble();
    final estimatedDuration = actualDuration ?? widget.tripData['estimatedDuration'] ?? 1;
    final departureTime = actualDepartureTime ?? widget.tripData['departureDate'] ?? DateTime.now();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WaitingScheduleScreen(
          scheduledDepartureTime: departureTime,
          tripData: {
            'vesselName': widget.tripData['vesselName'] ?? '',
            'vesselNumber': widget.tripData['vesselNumber'] ?? '',
            'captainName': widget.tripData['captainName'] ?? '',
            'crewCount': widget.tripData['crewCount'] ?? 0,
            'selectedHarbor': widget.tripData['departureHarbor'] ?? '',
            'departureTime': departureTime,
            'estimatedReturnDate': estimatedReturnDate,
            'estimatedDuration': estimatedDuration,
            'emergencyContact': widget.tripData['emergencyContact'] ?? '',
            'fuelAmount': fuelAmount,
            'iceStorage': iceStorage,
            'notes': widget.tripData['notes'],
            'harborCoordinates': widget.tripData['harborCoordinates'],
            'zoneRadius': PollingConfig.zoneRadius,
            'userRole': finalUserRole,
            'userName': userName,
          },
        ),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Menunggu Persetujuan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateToHome,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/PreTrip.json',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                Text(
                  _state == ApprovalState.timeout
                      ? 'Waktu Tunggu Habis'
                      : _state == ApprovalState.error
                          ? 'Terjadi Kesalahan'
                          : 'Menunggu Persetujuan Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _state == ApprovalState.timeout
                      ? 'Silakan coba lagi atau hubungi admin.'
                      : _state == ApprovalState.error
                          ? _errorMessage ?? 'Terjadi kesalahan saat memeriksa status.'
                          : 'Data trip sedang ditinjau admin.\nAnda akan diarahkan otomatis setelah disetujui.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.directions_boat, 'Kapal', widget.tripData['vesselName'] ?? '-'),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.numbers, 'No. Registrasi', widget.tripData['vesselNumber'] ?? '-'),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.group, 'Jumlah ABK', '${widget.tripData['crewCount'] ?? 0} orang'),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.location_on, 'Pelabuhan', widget.tripData['departureHarbor'] ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_state == ApprovalState.polling || _state == ApprovalState.loading)
                  const CircularProgressIndicator(color: Color(0xFF1B4F9C)),
                if (_state == ApprovalState.error || _state == ApprovalState.timeout)
                  ElevatedButton.icon(
                    onPressed: _startPolling,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F9C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1B4F9C), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
