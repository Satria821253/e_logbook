import 'dart:io';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/catch_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      appBar: isTablet ? null : _buildAppBar(context, isTablet),
      body: Consumer<CatchProvider>(
        builder: (context, catchProvider, child) {
          if (isTablet) {
            return _buildTabletLayout(catchProvider);
          }
          return _buildMobileLayout(catchProvider);
        },
      ),
    );
  }

  // ========================================================================
  // APP BAR
  // ========================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        'Riwayat Tangkapan',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: isTablet ? 20 : 18,
        ),
      ),
      centerTitle: true,
    );
  }

  // ========================================================================
  // MOBILE LAYOUT
  // ========================================================================
  Widget _buildMobileLayout(CatchProvider catchProvider) {
    return Builder(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        double fs(double size) => size * (width / 390);
        double sp(double value) => value * (width / 390);

        return ListView(
          padding: EdgeInsets.all(sp(16)),
          children: [
            _buildSummaryCardMobile(catchProvider, fs, sp),
            SizedBox(height: sp(20)),

            if (catchProvider.catches.isEmpty)
              _buildEmptyStateWithDummy(fs, sp)
            else
              ..._buildGroupedCatchesMobile(catchProvider.catches, fs, sp),
          ],
        );
      },
    );
  }

  // ========================================================================
  // TABLET LAYOUT
  // ========================================================================
  Widget _buildTabletLayout(CatchProvider catchProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _buildSummaryCardTablet(catchProvider),
          const SizedBox(height: 20),

          if (catchProvider.catches.isEmpty)
            _buildEmptyStateWithDummyTablet()
          else
            _buildGroupedCatchesTablet(catchProvider.catches),
        ],
      ),
    );
  }

  // ========================================================================
  // SUMMARY CARD - MOBILE
  // ========================================================================
  Widget _buildSummaryCardMobile(
    CatchProvider provider,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(sp(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4F9C).withOpacity(0.3),
            blurRadius: sp(15),
            offset: Offset(0, sp(5)),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Bulan Ini',
            style: TextStyle(
              color: Colors.white70,
              fontSize: fs(14),
            ),
          ),
          SizedBox(height: sp(8)),
          Text(
            'Rp ${_formatMoney(provider.totalRevenueThisMonth)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: fs(32),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sp(16)),
          Divider(color: Colors.white30, height: 1),
          SizedBox(height: sp(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItemMobile(
                'Total Tangkapan',
                '${provider.totalWeightThisMonth.toStringAsFixed(1)} kg',
                Icons.scale_rounded,
                fs,
                sp,
              ),
              Container(width: 1, height: sp(40), color: Colors.white30),
              _buildStatItemMobile(
                'Total Trip',
                '${provider.totalTripsThisMonth} Trip',
                Icons.sailing_rounded,
                fs,
                sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemMobile(
    String label,
    String value,
    IconData icon,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: fs(24)),
        SizedBox(height: sp(8)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: fs(12),
          ),
        ),
        SizedBox(height: sp(4)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fs(18),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // SUMMARY CARD - TABLET
  // ========================================================================
  Widget _buildSummaryCardTablet(CatchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4F9C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Bulan Ini',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_formatMoney(provider.totalRevenueThisMonth)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 60, color: Colors.white30),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatItemTablet(
              'Total Tangkapan',
              '${provider.totalWeightThisMonth.toStringAsFixed(1)} kg',
              Icons.scale_rounded,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatItemTablet(
              'Total Trip',
              '${provider.totalTripsThisMonth} Trip',
              Icons.sailing_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemTablet(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // EMPTY STATE WITH DUMMY DATA
  // ========================================================================
  Widget _buildEmptyStateWithDummy(
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(sp(48)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(sp(16)),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: fs(80), color: Colors.grey[400]),
              SizedBox(height: sp(16)),
              Text(
                'Belum Ada Riwayat',
                style: TextStyle(
                  fontSize: fs(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: sp(8)),
              Text(
                'Mulai catat tangkapan Anda',
                style: TextStyle(fontSize: fs(14), color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        SizedBox(height: sp(24)),
        _buildDummyDataSection(fs, sp),
      ],
    );
  }

  Widget _buildEmptyStateWithDummyTablet() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Riwayat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai catat tangkapan Anda',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildDummyDataSectionTablet(),
      ],
    );
  }

  // ========================================================================
  // DUMMY DATA PREVIEW
  // ========================================================================
  Widget _buildDummyDataSection(
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: fs(20)),
              SizedBox(width: sp(8)),
              Text(
                'Preview Data Contoh',
                style: TextStyle(
                  fontSize: fs(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: sp(12)),
          Text(
            'Berikut contoh tampilan riwayat tangkapan Anda nanti:',
            style: TextStyle(fontSize: fs(13), color: Colors.blue[700]),
          ),
          SizedBox(height: sp(16)),
          ..._buildDummyItems(fs, sp),
        ],
      ),
    );
  }

  Widget _buildDummyDataSectionTablet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Preview Data Contoh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Berikut contoh tampilan riwayat tangkapan Anda nanti:',
            style: TextStyle(fontSize: 14, color: Colors.blue[700]),
          ),
          const SizedBox(height: 20),
          _buildDummyItemsTablet(),
        ],
      ),
    );
  }

  List<Widget> _buildDummyItems(
    double Function(double) fs,
    double Function(double) sp,
  ) {
    final dummyData = _getDummyData();
    return dummyData.map((data) => _buildDummyCard(data, fs, sp)).toList();
  }

  Widget _buildDummyItemsTablet() {
    final dummyData = _getDummyData();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dummyData.length,
      itemBuilder: (context, index) => _buildDummyCardTablet(dummyData[index]),
    );
  }

  Widget _buildDummyCard(
    Map<String, dynamic> data,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: sp(12)),
      padding: EdgeInsets.all(sp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: sp(80),
            height: sp(80),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(sp(10)),
            ),
            child: Icon(Icons.image_outlined, color: Colors.blue[300], size: fs(40)),
          ),
          SizedBox(width: sp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: TextStyle(
                    fontSize: fs(15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: sp(6)),
                Row(
                  children: [
                    Icon(Icons.scale_rounded, size: fs(13), color: Colors.grey[600]),
                    SizedBox(width: sp(4)),
                    Text(
                      '${data['weight']} kg',
                      style: TextStyle(fontSize: fs(12), color: Colors.grey[600]),
                    ),
                    SizedBox(width: sp(12)),
                    Icon(Icons.access_time_rounded, size: fs(13), color: Colors.grey[600]),
                    SizedBox(width: sp(4)),
                    Text(
                      data['time'],
                      style: TextStyle(fontSize: fs(12), color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: sp(4)),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: fs(13), color: Colors.grey[600]),
                    SizedBox(width: sp(4)),
                    Expanded(
                      child: Text(
                        data['location'],
                        style: TextStyle(fontSize: fs(12), color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${data['revenue']}',
                style: TextStyle(
                  fontSize: fs(14),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B4F9C),
                ),
              ),
              SizedBox(height: sp(6)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: sp(8), vertical: sp(4)),
                decoration: BoxDecoration(
                  color: _conditionColor(data['condition']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(sp(6)),
                ),
                child: Text(
                  data['condition'],
                  style: TextStyle(
                    fontSize: fs(10),
                    fontWeight: FontWeight.w600,
                    color: _conditionColor(data['condition']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDummyCardTablet(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.image_outlined, color: Colors.blue[300], size: 35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${data['revenue']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.scale_rounded, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${data['weight']} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                data['time'],
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data['location'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _conditionColor(data['condition']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data['condition'],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _conditionColor(data['condition']),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDummyData() {
    return [
      {
        'name': 'Ikan Tuna',
        'weight': '25.5',
        'time': '06:00',
        'location': 'Perairan Utara Jawa',
        'revenue': '2.5jt',
        'condition': 'Segar',
      },
      {
        'name': 'Ikan Kakap',
        'weight': '18.3',
        'time': '07:30',
        'location': 'Selat Sunda',
        'revenue': '1.8jt',
        'condition': 'Cukup Segar',
      },
      {
        'name': 'Ikan Kembung',
        'weight': '35.0',
        'time': '05:15',
        'location': 'Laut Jawa Tengah',
        'revenue': '3.2jt',
        'condition': 'Segar',
      },
    ];
  }

  // ========================================================================
  // GROUPED CATCHES - MOBILE
  // ========================================================================
  List<Widget> _buildGroupedCatchesMobile(
    List<CatchModel> catches,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    final grouped = <String, List<CatchModel>>{};

    for (var c in catches) {
      final dateKey = DateFormat('yyyy-MM-dd').format(c.departureDate);
      grouped.putIfAbsent(dateKey, () => []).add(c);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final widgets = <Widget>[];

    grouped.forEach((dateKey, list) {
      final date = DateTime.parse(dateKey);

      String label;
      if (_isSameDay(date, today)) {
        label = "Hari Ini - ${DateFormat('dd MMM yyyy').format(date)}";
      } else if (_isSameDay(date, yesterday)) {
        label = "Kemarin - ${DateFormat('dd MMM yyyy').format(date)}";
      } else {
        label = DateFormat('dd MMM yyyy').format(date);
      }

      widgets.add(_buildDateSection(label, fs, sp));
      widgets.add(SizedBox(height: sp(10)));

      for (var c in list) {
        widgets.add(_historyItemMobile(c, fs, sp));
      }

      widgets.add(SizedBox(height: sp(20)));
    });

    return widgets;
  }

  Widget _buildDateSection(String text, double Function(double) fs, double Function(double) sp) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sp(6)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fs(16),
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B4F9C),
        ),
      ),
    );
  }

  Widget _historyItemMobile(
    CatchModel data,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () => NavigationHelper.pushNamedNoTransition(
            context,
            '/catch-detail',
            arguments: {'catchData': data},
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: sp(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(sp(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: sp(8),
                  offset: Offset(0, sp(2)),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(sp(16)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(sp(12)),
                    child: data.photoPath.isNotEmpty
                        ? Image.file(
                            File(data.photoPath),
                            width: sp(100),
                            height: sp(100),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: sp(100),
                            height: sp(100),
                            color: Colors.blue.withOpacity(0.1),
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey, size: fs(40)),
                          ),
                  ),
                  SizedBox(width: sp(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.fishName,
                          style: TextStyle(
                            fontSize: fs(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sp(6)),
                        Row(
                          children: [
                            Icon(Icons.scale_rounded,
                                size: fs(14), color: Colors.grey[600]),
                            SizedBox(width: sp(4)),
                            Text(
                              '${data.weight} kg',
                              style: TextStyle(
                                fontSize: fs(13),
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: sp(12)),
                            Icon(Icons.access_time_rounded,
                                size: fs(14), color: Colors.grey[600]),
                            SizedBox(width: sp(4)),
                            Text(
                              data.departureTime,
                              style: TextStyle(
                                fontSize: fs(13),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sp(4)),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: fs(14), color: Colors.grey[600]),
                            SizedBox(width: sp(4)),
                            Expanded(
                              child: Text(
                                data.locationName,
                                style: TextStyle(
                                  fontSize: fs(13),
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sp(6)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sp(8),
                            vertical: sp(4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(sp(6)),
                          ),
                          child: Text(
                            data.fishingZone.split(' - ')[0],
                            style: TextStyle(
                              fontSize: fs(10),
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_formatMoney(data.totalRevenue)}',
                        style: TextStyle(
                          fontSize: fs(15),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B4F9C),
                        ),
                      ),
                      SizedBox(height: sp(4)),
                      Text(
                        '${data.tripDurationHours}j ${data.tripDurationMinutes}m',
                        style: TextStyle(fontSize: fs(11), color: Colors.grey[600]),
                      ),
                      SizedBox(height: sp(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: sp(8), vertical: sp(4)),
                        decoration: BoxDecoration(
                          color: _conditionColor(data.condition).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(sp(8)),
                        ),
                        child: Text(
                          data.condition,
                          style: TextStyle(
                            fontSize: fs(11),
                            fontWeight: FontWeight.w600,
                            color: _conditionColor(data.condition),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // GROUPED CATCHES - TABLET
  // ========================================================================
  Widget _buildGroupedCatchesTablet(List<CatchModel> catches) {
    final grouped = <String, List<CatchModel>>{};

    for (var c in catches) {
      final dateKey = DateFormat('yyyy-MM-dd').format(c.departureDate);
      grouped.putIfAbsent(dateKey, () => []).add(c);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return Column(
      children: grouped.entries.map((entry) {
        final dateKey = entry.key;
        final list = entry.value;
        final date = DateTime.parse(dateKey);

        String label;
        if (_isSameDay(date, today)) {
          label = "Hari Ini - ${DateFormat('dd MMM yyyy').format(date)}";
        } else if (_isSameDay(date, yesterday)) {
          label = "Kemarin - ${DateFormat('dd MMM yyyy').format(date)}";
        } else {
          label = DateFormat('dd MMM yyyy').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) => _historyItemTablet(list[index]),
            ),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _historyItemTablet(CatchModel data) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () => NavigationHelper.pushNamedNoTransition(
            context,
            '/catch-detail',
            arguments: {'catchData': data},
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: data.photoPath.isNotEmpty
                          ? Image.file(
                              File(data.photoPath),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              color: Colors.blue.withOpacity(0.1),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 30),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.fishName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${_formatMoney(data.totalRevenue)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4F9C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.scale_rounded, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${data.weight} kg',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      data.departureTime,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data.locationName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.fishingZone.split(' - ')[0],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _conditionColor(data.condition).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.condition,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _conditionColor(data.condition),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _conditionColor(String v) {
    switch (v) {
      case 'Segar':
        return Colors.green;
      case 'Cukup Segar':
        return Colors.orange;
      case 'Kurang Segar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }
}