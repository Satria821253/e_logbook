import 'package:e_logbook/widgets/catch_corousel.dart';
import 'package:e_logbook/widgets/custom_silver_appbar.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/screens/documents/document_upload_stepper.dart';
import 'package:e_logbook/screens/documents/document_popup_helper.dart';
import 'package:e_logbook/screens/documents/pending_popup_helper.dart';
import 'package:e_logbook/services/getAPi/document_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/catch_provider.dart';
import '../provider/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool _showDocumentAlert = false;
  bool _showPendingBanner = false;
  bool _showRejectedAlert = false;
  int _pendingCount = 0;
  int _rejectedCount = 0;
  int _totalCount = 8;
  bool _hasShownPopup = false;
  bool _hasLoggedInit = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🚀 HomeScreen: initState called');
    
    // Clear popup session flag saat app dibuka
    _clearPopupSessionFlag();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }
  
  Future<void> _clearPopupSessionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('popup_shown_this_session');
    print('🧹 Cleared popup session flag');
  }



  Future<void> _loadAllData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserFromStorage();
    
    await _checkDocumentCompletion();
    
    if (!_hasLoggedInit) {
      print('🔍 HomeScreen: _hasShownPopup = $_hasShownPopup');
      _hasLoggedInit = true;
    }
    
    if (!_hasShownPopup && mounted) {
      await _checkAndShowPopup();
      _hasShownPopup = true;
    }
  }

  Future<void> _checkAndShowPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsCompleted = prefs.getBool('documents_completed') ?? false;
    final documentsPending = prefs.getBool('documents_pending') ?? false;
    final hasRejected = prefs.getBool('has_rejected_documents') ?? false;
    final approvedCount = prefs.getInt('approved_count') ?? 0;
    
    // Check if popup already shown in this session
    final popupShownThisSession = prefs.getBool('popup_shown_this_session') ?? false;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.user?.role ?? 'Crew';
    
    print('👤 HomeScreen: User role = $userRole');
    print('📋 HomeScreen: completed=$documentsCompleted, pending=$documentsPending, rejected=$hasRejected');
    print('🔒 Popup shown this session: $popupShownThisSession');

    // Jika semua dokumen sudah completed, jangan tampilkan popup apapun
    if (documentsCompleted) {
      print('✅ HomeScreen: All documents completed, no popup needed');
      return;
    }
    
    // Jika popup sudah ditampilkan di session ini, skip
    if (popupShownThisSession) {
      print('⏭️ HomeScreen: Popup already shown this session, skip');
      return;
    }

    // Jika ada rejected, tampilkan popup rejected (prioritas tertinggi)
    if (hasRejected && mounted) {
      print('🔴 HomeScreen: Showing rejected popup');
      await prefs.setBool('popup_shown_this_session', true);
      PendingPopupHelper.showPendingPopup(
        context: context,
        userRole: userRole,
        pendingCount: _pendingCount,
        approvedCount: approvedCount,
        rejectedCount: _rejectedCount,
        totalCount: _totalCount,
      );
      return;
    }
    
    // Jika ada pending, tampilkan pending popup
    if (documentsPending && mounted) {
      print('🟠 HomeScreen: Showing pending popup');
      await prefs.setBool('popup_shown_this_session', true); // Mark as shown
      PendingPopupHelper.showPendingPopup(
        context: context,
        userRole: userRole,
        pendingCount: _pendingCount,
        approvedCount: approvedCount,
        rejectedCount: _rejectedCount,
        totalCount: _totalCount,
      );
      return;
    }

    // Jika ada rejected, jangan tampilkan popup (sudah ada banner)
    if (hasRejected) {
      print('🔴 HomeScreen: Has rejected docs, showing banner only');
      return;
    }

    // Jika belum lengkap dan tidak ada pending/rejected, tampilkan upload popup
    if (!documentsCompleted && !documentsPending && !hasRejected && mounted) {
      print('🎯 HomeScreen: Showing document upload popup');
      await prefs.setBool('popup_shown_this_session', true); // Mark as shown
      DocumentPopupHelper.showDocumentPopup(context, userRole);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-reload ketika app resumed (kembali dari background)
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, refreshing document status...');
      _checkDocumentCompletion();
    }
  }

  Future<void> _checkDocumentCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get real document counts from API with error handling
    try {
      final response = await DocumentService.getDocuments().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Document fetch timeout - using cached data');
          return {'success': false};
        },
      );
      
      if (response['success'] == true) {
        final docs = response['documents'] as List;
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final rejected = docs.where((d) => d['status'] == 'rejected').length;
        final total = docs.length;
        
        print('📊 [Document Status] Total: $total, Approved: $approved, Pending: $pending, Rejected: $rejected');
        
        // Jika tidak ada dokumen sama sekali, reset semua status
        if (total == 0) {
          await prefs.setBool('documents_completed', false);
          await prefs.setBool('documents_pending', false);
          await prefs.setBool('has_rejected_documents', false);
          print('🧹 [Reset] No documents found, cleared all status');
          
          if (mounted) {
            setState(() {
              _pendingCount = 0;
              _rejectedCount = 0;
              _totalCount = 8;
              _showDocumentAlert = true; // Tampilkan alert upload
              _showPendingBanner = false;
              _showRejectedAlert = false;
            });
          }
          return;
        }
        
        // Validasi: 
        // - Dokumen completed jika semua 8 dokumen sudah approved
        // - Pending popup HANYA muncul jika SEMUA 8 dokumen sudah diupload DAN ada yang pending
        // - Upload popup muncul jika belum lengkap 8 dokumen
        final allDocsApproved = approved >= 8;
        final totalUploaded = approved + pending;
        const totalRequired = 8;
        
        // Pending hanya jika sudah upload semua 8 dokumen dan ada yang masih pending
        final hasPending = totalUploaded >= totalRequired && pending > 0;
        final hasRejected = rejected > 0;
        
        // Update status
        await prefs.setBool('documents_completed', allDocsApproved);
        await prefs.setBool('documents_pending', hasPending);
        await prefs.setBool('has_rejected_documents', hasRejected);
        await prefs.setInt('approved_count', approved);
        await prefs.setInt('total_uploaded', totalUploaded);
        
        print('✅ [Validation] Approved: $approved, Pending: $pending, Total: $totalUploaded/8, Show pending popup: $hasPending');
        
        if (mounted) {
          setState(() {
            _pendingCount = pending;
            _rejectedCount = rejected;
            _totalCount = 8; // Total dokumen yang dibutuhkan
            
            // Hanya tampilkan alert jika belum semua approved dan tidak ada pending/rejected
            _showDocumentAlert = !allDocsApproved && !hasPending && !hasRejected;
            _showPendingBanner = hasPending;
            _showRejectedAlert = hasRejected && !hasPending;
          });
        }
        return;
      }
    } catch (e) {
      print('⚠️ Error fetching documents (offline mode): $e');
    }
    
    // Fallback if API fails - use cached data
    final documentsCompleted = prefs.getBool('documents_completed') ?? false;
    final documentsPending = prefs.getBool('documents_pending') ?? false;
    final hasRejected = prefs.getBool('has_rejected_documents') ?? false;
    
    if (mounted) {
      setState(() {
        _showDocumentAlert = !documentsCompleted && !documentsPending && !hasRejected;
        _showPendingBanner = documentsPending;
        _showRejectedAlert = hasRejected && !documentsPending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
      body: RefreshIndicator(
        onRefresh: _checkDocumentCompletion,
        child: CustomScrollView(
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
                  ValueListenableBuilder<bool>(
                    valueListenable: DocumentPopupHelper.isPopupVisible,
                    builder: (context, isPopupVisible, child) {
                      if (_showDocumentAlert && !isPopupVisible) {
                        return Column(
                          children: [
                            _buildDocumentAlert(),
                            SizedBox(
                              height: ResponsiveHelper.height(
                                context,
                                mobile: 16,
                                tablet: 20,
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
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

                  // Rejected Alert (berbeda dengan document alert)
                  if (_showRejectedAlert) _buildRejectedAlert(),
                  if (_showRejectedAlert)
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentUploadStepper(),
                  ),
                );
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
  
  Widget _buildRejectedAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
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
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dokumen Ditolak!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_rejectedCount dokumen perlu diupload ulang',
                      style: const TextStyle(
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
              onPressed: () {
                Navigator.pushNamed(context, '/document-status');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Upload Ulang Dokumen',
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
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
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
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 1.0, end: 1.2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pending,
                        color: Color(0xFFFB8C00),
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text(
                  'Lihat Detail',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
