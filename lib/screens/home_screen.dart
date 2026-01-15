import 'package:e_logbook/widgets/catch_corousel.dart';
import 'package:e_logbook/widgets/custom_silver_appbar.dart';
import 'package:e_logbook/screens/document_completion_screen.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/catch_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDocumentAlert = false;
  bool _showPendingBanner = false;

  @override
  void initState() {
    super.initState();
    _checkDocumentCompletion();
  }

  Future<void> _checkDocumentCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsCompleted = prefs.getBool('documents_completed') ?? false;
    final documentsPending = prefs.getBool('documents_pending') ?? false;
    
    if (mounted) {
      setState(() {
        _showDocumentAlert = !documentsCompleted && !documentsPending;
        _showPendingBanner = documentsPending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    if (isTablet) {
      // Tablet layout dengan SingleChildScrollView
      return SingleChildScrollView(
        child: Container(
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildTabletLayout(),
          ),
        ),
      );
    }

    // Mobile layout dengan CustomScrollView
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
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

                  // Document Alert
                  if (_showDocumentAlert) _buildDocumentAlert(),
                  if (_showDocumentAlert)
                    SizedBox(
                      height: ResponsiveHelper.height(
                        context,
                        mobile: 16,
                        tablet: 20,
                      ),
                    ),
                  
                  // Pending Banner
                  if (_showPendingBanner) _buildPendingBanner(),
                  if (_showPendingBanner)
                    SizedBox(
                      height: ResponsiveHelper.height(
                        context,
                        mobile: 16,
                        tablet: 20,
                      ),
                    ),

                  // Statistics Container
                  Container(
                    padding: ResponsiveHelper.padding(
                      context,
                      mobile: 20,
                      tablet: 24,
                    ),
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
                        _buildStatisticsCards(),
                      ],
                    ),
                  ),

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

                  // Recent Catches Container
                  Container(
                    padding: ResponsiveHelper.padding(
                      context,
                      mobile: 20,
                      tablet: 24,
                    ),
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
                    child: _buildRecentCatches(),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 20,
                      tablet: 28,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
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
              width: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
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
          height: ResponsiveHelper.height(context, mobile: 12, tablet: 16),
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
              width: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
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
      padding: ResponsiveHelper.padding(context, mobile: 12, tablet: 20),
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
            blurRadius: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
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
            width: ResponsiveHelper.width(context, mobile: 40, tablet: 60),
            height: ResponsiveHelper.height(context, mobile: 40, tablet: 60),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.width(context, mobile: 12, tablet: 15),
              ),
            ),
            child: Center(
              child: Lottie.asset(
                lottieAsset,
                width: ResponsiveHelper.width(context, mobile: 40, tablet: 60),
                height: ResponsiveHelper.height(
                  context,
                  mobile: 40,
                  tablet: 60,
                ),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: ResponsiveHelper.width(
                      context,
                      mobile: 24,
                      tablet: 36,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.height(context, mobile: 8, tablet: 16),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 14),
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.height(context, mobile: 4, tablet: 6),
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
                width: ResponsiveHelper.width(context, mobile: 4, tablet: 6),
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
        ]
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
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
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dokumen Pribadi Belum Lengkap!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lengkapi dokumen pribadi Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentCompletionScreen(),
                  ),
                );
                if (result == true || mounted) {
                  _checkDocumentCompletion();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Lengkapi Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
                child: const Icon(
                  Icons.pending,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dokumen Sedang Diverifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Menunggu persetujuan admin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/document-status');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Lihat Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('documents_pending');
                    if (mounted) {
                      setState(() {
                        _showPendingBanner = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status pending dihapus. Anda bisa kirim ulang dokumen.'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel - Full width
        CatchCarousel(),
        const SizedBox(height: 24),

        // Document Alert - Admin sends from web, appears here automatically
        // TODO: Uncomment when backend ready
        // if (!_isLoadingDocuments && _documentRequirements.isNotEmpty)
        //   _buildDocumentAlert(),
        // if (!_isLoadingDocuments && _documentRequirements.isNotEmpty)
        //   const SizedBox(height: 24),

        // Statistics Title and Cards in white container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistik Hari Ini',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildTabletStatisticsCards(),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Weekly Activity Chart - Full width
        _buildWeeklyActivity(),
        const SizedBox(height: 32),

        // Recent Catches - Full width below chart
        _buildRecentCatches(),
      ],
    );
  }

  Widget _buildTabletStatisticsCards() {
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

    return Row(
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
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernStatCard(
            lottieAsset: 'assets/animations/Weighing.json',
            label: 'Total Berat',
            value: totalWeight.toStringAsFixed(1),
            subtitle: 'kg',
            gradientColors: [Color(0xFF5CB85C), Color(0xFF449D44)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernStatCard(
            lottieAsset: 'assets/animations/money.json',
            label: 'Pendapatan',
            value: '${(totalRevenue / 1000).toStringAsFixed(0)}k',
            subtitle: 'Rupiah',
            gradientColors: [Color(0xFFF0AD4E), Color(0xFFEC971F)],
          ),
        ),
        const SizedBox(width: 16),
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
    );
  }
}
