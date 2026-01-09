import 'package:e_logbook/widgets/catch_corousel.dart';
import 'package:e_logbook/widgets/custom_silver_appbar.dart';
import 'package:e_logbook/screens/document_completion_screen.dart';
import 'package:e_logbook/services/admin_notification_service.dart';
import 'package:e_logbook/services/data_clear_service.dart';
import 'package:e_logbook/models/document_requirement_model.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../provider/catch_provider.dart';
import '../provider/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DocumentRequirementModel> _documentRequirements = [];
  bool _isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentRequirements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocumentRequirements();
    });
  }

  Future<void> _loadDocumentRequirements() async {
    // Check if full process is completed
    bool isFullyCompleted = await _checkFullCompletion();

    if (isFullyCompleted) {
      // Hide document alert if fully completed
      setState(() {
        _documentRequirements = [];
        _isLoadingDocuments = false;
      });
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      final requirements =
          await AdminNotificationService.getDocumentRequirementsForUser(
            user.email,
          );
      if (mounted) {
        // Calculate real completion percentage
        final completion = await _calculateCompletionPercentage();

        // Only show popup if completion is less than 100%
        if (completion < 1.0) {
          final updatedRequirements = requirements.map((req) {
            return DocumentRequirementModel(
              id: req.id,
              userId: req.userId,
              userRole: req.userRole,
              title: req.title,
              description: req.description,
              requiredDocuments: req.requiredDocuments,
              createdAt: req.createdAt,
              isUrgent: req.isUrgent,
              isCompleted: false, // Always false since completion < 1.0
              dueDate: req.dueDate,
            );
          }).toList();

          setState(() {
            _documentRequirements = updatedRequirements;
            _isLoadingDocuments = false;
          });
        } else {
          // Completion is 100%, hide popup
          setState(() {
            _documentRequirements = [];
            _isLoadingDocuments = false;
          });
        }
      }
    }
  }

  Future<bool> _checkFullCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('full_process_completed') ?? false;
    print('DEBUG: _checkFullCompletion = $isCompleted');
    return isCompleted;
  }

  Future<double> _calculateCompletionPercentage() async {
    final prefs = await SharedPreferences.getInstance();

    int completedFields = 0;
    int totalFields = 5; // Documents (3 minimum) + Fuel + Ice + Certificates

    // Check documents (count minimum 3 required documents)
    final documentsJson = prefs.getStringList('documents') ?? [];
    final documents = documentsJson.map((doc) => json.decode(doc)).toList();
    final uploadedDocs = documents
        .where((doc) => doc['isUploaded'] == true)
        .length;

    // Only count up to 3 documents maximum for completion
    if (uploadedDocs >= 3) {
      completedFields += 3; // Max 3 documents
    } else {
      completedFields += uploadedDocs; // Less than 3
    }

    // Check fuel
    final fuel = prefs.getString('vessel_fuel') ?? '';
    if (fuel.isNotEmpty) completedFields++;

    // Check ice
    final ice = prefs.getString('vessel_ice') ?? '';
    if (ice.isNotEmpty) completedFields++;

    // Check certificates
    final certificates = prefs.getStringList('vessel_certificates') ?? [];
    if (certificates.isNotEmpty) completedFields++;

    final completion = (completedFields / totalFields).clamp(0.0, 1.0);
    print('DEBUG: Completion = $completion ($completedFields/$totalFields)');
    print(
      'DEBUG: Documents = $uploadedDocs, Fuel = ${fuel.isNotEmpty}, Ice = ${ice.isNotEmpty}, Certificates = ${certificates.length}',
    );

    return completion;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CustomSliverAppBar(),
        // Content
        SliverToBoxAdapter(
          child: Container(
            color: Colors.grey[50],
            child: Padding(
              padding: ResponsiveHelper.padding(
                context,
                mobile: 20,
                tablet: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carousel
                  CatchCarousel(),
                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 16,
                      tablet: 20,
                    ),
                  ),

                  // Document Requirements Alert
                  if (!_isLoadingDocuments && _documentRequirements.isNotEmpty)
                    _buildDocumentAlert(),

                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 24,
                      tablet: 32,
                    ),
                  ),

                  // Statistics Title
                  Text(
                    'Statistik Hari Ini',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 20,
                        tablet: 24,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 16,
                      tablet: 20,
                    ),
                  ),

                  // Statistics Cards
                  _buildStatisticsCards(),

                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 28,
                      tablet: 36,
                    ),
                  ),

                  // Weekly Activity Chart
                  _buildWeeklyActivity(),

                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 28,
                      tablet: 36,
                    ),
                  ),

                  // Recent Catches
                  _buildRecentCatches(),

                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 20,
                      tablet: 28,
                    ),
                  ),

                  // Dummy Data Setup Button (for testing)
                  _buildDummyDataButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    final provider = Provider.of<CatchProvider>(context);
    final todayCatches = provider.todayCatches;
    final totalWeight = todayCatches.fold<double>(
      0,
      (sum, catch_) => sum + catch_.weight,
    );
    final totalRevenue = todayCatches.fold<double>(
      0,
      (sum, catch_) => sum + catch_.totalRevenue,
    );

    final averageWeight = todayCatches.isEmpty
        ? 0.0
        : totalWeight / todayCatches.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                lottieAsset: 'assets/animations/fish.json',
                label: 'Tangkapan',
                value: '${todayCatches.length}',
                subtitle: 'ikan',
                gradientColors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.width(
                context,
                mobile: 12,
                tablet: 16,
              ),
            ),
            Expanded(
              child: _buildModernStatCard(
                lottieAsset: 'assets/animations/Weighing.json',
                label: 'Total Berat',
                value: totalWeight.toStringAsFixed(1),
                subtitle: 'kg',
                gradientColors: [Color(0xFF5CB85C), Color(0xFF449D44)],
              ),
            ),
          ],
        ),
        SizedBox(
          height: ResponsiveHelper.height(
            context,
            mobile: 12,
            tablet: 16,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                lottieAsset: 'assets/animations/money.json',
                label: 'Pendapatan',
                value: '${(totalRevenue / 1000).toStringAsFixed(0)}k',
                subtitle: 'Rupiah',
                gradientColors: [Color(0xFFF0AD4E), Color(0xFFEC971F)],
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.width(
                context,
                mobile: 12,
                tablet: 16,
              ),
            ),
            Expanded(
              child: _buildModernStatCard(
                lottieAsset: 'assets/animations/chart.json',
                label: 'Rata-rata',
                value: averageWeight.toStringAsFixed(1),
                subtitle: 'kg/ikan', 
                gradientColors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String lottieAsset,
    required String label,
    required String value,
    required String subtitle,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: ResponsiveHelper.padding(
        context,
        mobile: 16,
        tablet: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.width(context, mobile: 20, tablet: 24),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: ResponsiveHelper.width(
              context,
              mobile: 12,
              tablet: 16,
            ),
            offset: Offset(
              0,
              ResponsiveHelper.height(context, mobile: 6, tablet: 8),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lottie Animation
          Container(
            width: ResponsiveHelper.width(
              context,
              mobile: 50,
              tablet: 60,
            ),
            height: ResponsiveHelper.height(
              context,
              mobile: 50,
              tablet: 60,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.width(
                  context,
                  mobile: 12,
                  tablet: 15,
                ),
              ),
            ),
            child: Center(
              child: Lottie.asset(
                lottieAsset,
                width: ResponsiveHelper.width(
                  context,
                  mobile: 50,
                  tablet: 60,
                ),
                height: ResponsiveHelper.height(
                  context,
                  mobile: 50,
                  tablet: 60,
                ),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: ResponsiveHelper.width(
                      context,
                      mobile: 30,
                      tablet: 36,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.height(
              context,
              mobile: 12,
              tablet: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(
                context,
                mobile: 12,
                tablet: 14,
              ),
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.height(
              context,
              mobile: 4,
              tablet: 6,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(
                      context,
                      mobile: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: ResponsiveHelper.width(
                  context,
                  mobile: 4,
                  tablet: 6,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveHelper.height(
                    context,
                    mobile: 3,
                    tablet: 4,
                  ),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(
                      context,
                      mobile: 11,
                      tablet: 13,
                    ),
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity() {
    final provider = Provider.of<CatchProvider>(context);

    // Generate data untuk 7 hari terakhir
    List<Map<String, dynamic>> weeklyData = _getWeeklyData(provider);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Mingguan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '7 Hari Terakhir',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Berat total tangkapan (kg)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeklyData[value.toInt()]['day'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (weeklyData.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(weeklyData),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['weight'],
                      );
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF4A90E2),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF4A90E2),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A90E2).withOpacity(0.3),
                          const Color(0xFF4A90E2).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWeeklyData(CatchProvider provider) {
    final now = DateTime.now();
    final weekDays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = weekDays[date.weekday % 7];

      // Hitung total berat tangkapan untuk hari ini
      final dayWeight = provider.catches
          .where((catch_) {
            final catchDate = catch_.departureDate;
            return catchDate.year == date.year &&
                catchDate.month == date.month &&
                catchDate.day == date.day;
          })
          .fold<double>(0, (sum, catch_) => sum + catch_.weight);

      data.add({'day': dayName, 'weight': dayWeight});
    }

    return data;
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;

    final maxWeight = data
        .map((d) => d['weight'] as double)
        .reduce((a, b) => a > b ? a : b);

    // Tambahkan padding 20% untuk tampilan yang lebih baik
    final maxY = maxWeight * 1.2;

    // Bulatkan ke kelipatan 20 terdekat
    return ((maxY / 20).ceil() * 20).toDouble();
  }

  Widget _buildRecentCatches() {
    final provider = Provider.of<CatchProvider>(context);
    final recentCatches = provider.catches.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tangkapan Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to history
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentCatches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada tangkapan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentCatches.map(
            (catch_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4A90E2).withOpacity(0.2),
                          Color(0xFF4A90E2).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phishing_rounded,
                      color: Color(0xFF4A90E2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catch_.fishName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${catch_.weight} kg',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentAlert() {
    final urgentRequirements = _documentRequirements
        .where((req) => req.isUrgent)
        .toList();
    final hasUrgent = urgentRequirements.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasUrgent
              ? [Colors.red.shade400, Colors.red.shade600]
              : [const Color(0xFF1B4F9C), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasUrgent ? Colors.red : const Color(0xFF1B4F9C))
                .withOpacity(0.3),
            blurRadius: 12,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  hasUrgent ? Icons.warning : Icons.description,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUrgent
                          ? 'Dokumen Wajib Belum Lengkap!'
                          : 'Kelengkapan Dokumen',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasUrgent
                          ? 'Lengkapi dokumen sebelum memulai trip'
                          : 'Ada dokumen yang perlu dilengkapi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress for first requirement
          if (_documentRequirements.isNotEmpty) ...[
            FutureBuilder<double>(
              future: _calculateCompletionPercentage(),
              builder: (context, snapshot) {
                final completion = snapshot.data ?? 0.0;
                return Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completion,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(completion * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_documentRequirements.isNotEmpty) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentCompletionScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadDocumentRequirements();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: hasUrgent
                    ? Colors.red
                    : const Color(0xFF1B4F9C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                hasUrgent ? 'Lengkapi Sekarang' : 'Lihat Dokumen',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyDataButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            'Testing Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final user = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).user;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'User tidak ditemukan, silakan login ulang',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await DataClearService.setupDummyData(
                        user.email,
                        user.role ?? 'crew',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Dummy data berhasil dibuat untuk ${user.role}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadDocumentRequirements();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Setup Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await DataClearService.clearAllDummyData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data berhasil dihapus'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        _loadDocumentRequirements();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}