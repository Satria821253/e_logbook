import 'dart:io';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/screens/crew/screens/catch_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/catch_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- RESPONSIVE SCALE (SAMA seperti halaman lain) ---
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390); // font scale
    double sp(double value) => value * (width / 390); // spacing/padding scale

    return Scaffold(
      appBar: AppBar(
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
            fontSize: fs(18),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CatchProvider>(
        builder: (context, catchProvider, child) {
          return ListView(
            padding: EdgeInsets.all(sp(16)),
            children: [
              _buildSummaryCard(catchProvider, fs, sp),
              SizedBox(height: sp(20)),

              if (catchProvider.catches.isEmpty)
                _buildEmptyState(fs, sp)
              else
                ..._buildGroupedCatches(catchProvider.catches, fs, sp),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------------------
  Widget _buildEmptyState(double Function(double) fs, double Function(double) sp) {
    return Container(
      padding: EdgeInsets.all(sp(48)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(sp(16)),
      ),
      child: Center(
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
    );
  }

  // ----------------------------------------------------------------
  // GROUP CATCHES
  // ----------------------------------------------------------------
  List<Widget> _buildGroupedCatches(
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
        widgets.add(_historyItem(c, fs, sp));
      }

      widgets.add(SizedBox(height: sp(20)));
    });

    return widgets;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ----------------------------------------------------------------
  // SUMMARY CARD
  // ----------------------------------------------------------------
  Widget _buildSummaryCard(
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
          SizedBox(height: sp(20)),

          // row items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                'Total Tangkapan',
                '${provider.totalWeightThisMonth.toStringAsFixed(1)} kg',
                fs,
                sp,
              ),
              Container(
                width: sp(1),
                height: sp(35),
                color: Colors.white30,
              ),
              _summaryItem(
                'Total Trip',
                '${provider.totalTripsThisMonth} Trip',
                fs,
                sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fs(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sp(4)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: fs(12),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // SECTION LABEL
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // HISTORY ITEM
  // ----------------------------------------------------------------
  Widget _historyItem(
    CatchModel data,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatchDetailScreen(catchData: data),
            ),
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
                  // IMAGE
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

                  // INFO
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

                        // weight, time
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

                        // location
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

                        // zone
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

                  // RIGHT SIDE: Revenue & Condition
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
                        style:
                            TextStyle(fontSize: fs(11), color: Colors.grey[600]),
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
