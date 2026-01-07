import 'package:e_logbook/models/attendance_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CrewAttendanceScreen extends StatefulWidget {
  @override
  _CrewAttendanceScreenState createState() => _CrewAttendanceScreenState();
}

class _CrewAttendanceScreenState extends State<CrewAttendanceScreen> {
  String _selectedFilter = 'semua';
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = true;
  bool _showFilterPanel = false;
  final LayerLink _filterLink = LayerLink();
  OverlayEntry? _filterOverlay;

  void _removeFilterOverlay() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  @override
  void dispose() {
    _removeFilterOverlay();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Skip loading, use dummy data
    _attendanceRecords = [
      AttendanceModel(
        id: '1',
        crewName: 'Ahmad Rizki',
        vesselName: 'KM Bahari Jaya',
        tripDate: DateTime.now().subtract(Duration(days: 1)),
        status: 'hadir',
        reason: null,
        createdAt: DateTime.now(),
      ),
      AttendanceModel(
        id: '2',
        crewName: 'Budi Santoso',
        vesselName: 'KM Bahari Jaya',
        tripDate: DateTime.now().subtract(Duration(days: 1)),
        status: 'izin',
        reason: 'Sakit',
        createdAt: DateTime.now(),
      ),
      AttendanceModel(
        id: '3',
        crewName: 'Candra Wijaya',
        vesselName: 'KM Bahari Jaya',
        tripDate: DateTime.now().subtract(Duration(days: 2)),
        status: 'tidak_hadir',
        reason: 'Tanpa keterangan',
        createdAt: DateTime.now(),
      ),
      AttendanceModel(
        id: '4',
        crewName: 'Dedi Kurniawan',
        vesselName: 'KM Bahari Jaya',
        tripDate: DateTime.now().subtract(Duration(days: 3)),
        status: 'hadir',
        reason: null,
        createdAt: DateTime.now(),
      ),
      AttendanceModel(
        id: '5',
        crewName: 'Eko Prasetyo',
        vesselName: 'KM Bahari Jaya',
        tripDate: DateTime.now().subtract(Duration(days: 3)),
        status: 'izin',
        reason: 'Urusan keluarga',
        createdAt: DateTime.now(),
      ),
    ];
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(
              color: Colors.white, // ← warna arrow back
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
              'informasi Kapal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1B4F9C)),
                      SizedBox(height: 16),
                      Text('Memuat data kehadiran...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(height: 30),
                    _buildHeaderSection(user, _attendanceRecords),
                    SizedBox(height: 12),
                    _buildStatsCards(_attendanceRecords),
                    SizedBox(height: 12),
                    _buildSortButton(),
                    SizedBox(height: 12),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildContent(),
                          if (_showFilterPanel) _buildFilterPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildContent() {
    final filteredRecords = _getFilteredRecords(_attendanceRecords);
    final groupedByDate = _groupByDate(filteredRecords);

    if (filteredRecords.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAttendanceList(groupedByDate);
  }

  Widget _buildHeaderSection(user, List<AttendanceModel> records) {
     return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B4F9C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              'assets/animations/PreTrip.json', // ubah sesuai nama file Anda
              width: 100,
              height: 100,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'KM Bahari Jaya',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data kehadiran crew',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CompositedTransformTarget(
          link: _filterLink,
          child: GestureDetector(
            onTap: _toggleFilterOverlay,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Urutkan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4F9C),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: Color(0xFF1B4F9C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFilterOverlay() {
    if (_filterOverlay != null) {
      _removeFilterOverlay();
      return;
    }

    _filterOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeFilterOverlay,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _filterLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 32), // tepat di bawah "Urutkan"
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBubbleOption('Semua', 'semua'),
                          _buildBubbleOption('Hadir', 'hadir'),
                          _buildBubbleOption('Izin', 'izin'),
                          _buildBubbleOption('Tidak Hadir', 'tidak_hadir'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_filterOverlay!);
  }

  Widget _buildBubbleOption(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _removeFilterOverlay();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B4F9C).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF1B4F9C) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Color(0xFF1B4F9C)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showFilterPanel = false),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFilterOption(
                      'Semua',
                      'semua',
                      Icons.grid_view_rounded,
                      Colors.grey[600]!,
                    ),
                    SizedBox(height: 12),
                    _buildFilterOption(
                      'Hadir',
                      'hadir',
                      Icons.check_circle_rounded,
                      Colors.green,
                    ),
                    SizedBox(height: 12),
                    _buildFilterOption(
                      'Izin',
                      'izin',
                      Icons.schedule_rounded,
                      Colors.orange,
                    ),
                    SizedBox(height: 12),
                    _buildFilterOption(
                      'Tidak Hadir',
                      'tidak_hadir',
                      Icons.cancel_rounded,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _showFilterPanel = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey[600]),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            Spacer(),
            if (isSelected) Icon(Icons.check_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<AttendanceModel> records) {
    final hadirCount = records.where((r) => r.status == 'hadir').length;
    final izinCount = records.where((r) => r.status == 'izin').length;
    final tidakHadirCount = records
        .where((r) => r.status == 'tidak_hadir')
        .length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Hadir',
              hadirCount.toString(),
              Icons.check_circle_rounded,
              Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Izin',
              izinCount.toString(),
              Icons.schedule_rounded,
              Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tidak Hadir',
              tidakHadirCount.toString(),
              Icons.cancel_rounded,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Tidak ada data kehadiran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data kehadiran crew akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    Map<String, List<AttendanceModel>> groupedByDate,
  ) {
    final allRecords = <AttendanceModel>[];
    groupedByDate.values.forEach((records) => allRecords.addAll(records));

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    Color statusColor;

    switch (record.status) {
      case 'hadir':
        statusColor = Colors.green;
        break;
      case 'izin':
        statusColor = Colors.orange;
        break;
      case 'tidak_hadir':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.crewName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (record.reason != null) ...[
                  SizedBox(height: 4),
                  Text(
                    record.reason!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.status == 'hadir'
                      ? 'Hadir'
                      : record.status == 'izin'
                      ? 'Izin'
                      : 'Tidak Hadir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatDate(record.tripDate),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AttendanceModel> _getFilteredRecords(List<AttendanceModel> records) {
    if (_selectedFilter == 'semua') {
      return records;
    }
    return records.where((record) => record.status == _selectedFilter).toList();
  }

  Map<String, List<AttendanceModel>> _groupByDate(
    List<AttendanceModel> records,
  ) {
    final Map<String, List<AttendanceModel>> grouped = {};

    for (final record in records) {
      final dateKey = _formatDate(record.tripDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
