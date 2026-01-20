// lib/screens/documents/crew_pending_popup.dart

import 'package:e_logbook/screens/documents/document_status_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'dart:math' as math;

class CrewPendingPopup extends StatefulWidget {
  final int pendingCount;
  final int totalCount;

  const CrewPendingPopup({
    Key? key,
    this.pendingCount = 0,
    this.totalCount = 6,
  }) : super(key: key);

  @override
  State<CrewPendingPopup> createState() => _CrewPendingPopupState();
}

class _CrewPendingPopupState extends State<CrewPendingPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _waveController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeOutCubic,
    );

    _scaleController.forward();
    _rotateController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    super.dispose();
  }


  void _maximize() {
    setState(() => _isMinimized = false);
    _scaleController.forward();
  }

  void _closePopup() {
    _scaleController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closePopup();
        return false;
      },
      child: Stack(
        children: [
          // Background blur
          if (!_isMinimized)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

          // Minimized floating button
          if (_isMinimized)
            Positioned(
              bottom: 20,
              right: 20,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: _maximize,
                  child: Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hourglass_empty,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${widget.pendingCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main popup
          if (!_isMinimized)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: Tween<double>(begin: -0.02, end: 0.0).animate(_rotateAnimation),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: _buildPopupContent(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopupContent() {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF57C00),
            Color(0xFFFB8C00),
            Color(0xFFFFA726),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Animated sand timer effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SandTimerPainter(_waveController.value),
                );
              },
            ),
          ),

          // Floating hourglasses
          _buildFloatingHourglasses(),

          // Content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildPendingIllustration(),
                      const SizedBox(height: 24),
                      const Text(
                        '⏳ Sedang Diproses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.pendingCount} dokumen Anda sedang diperiksa admin',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildCountdownCard(),
                      const SizedBox(height: 24),
                      _buildQuickInfo(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.groups, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'ABK/CREW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _closePopup,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHourglasses() {
    return Stack(
      children: [
        _buildFloatingIcon(Icons.hourglass_top, 50, 100, 0),
        _buildFloatingIcon(Icons.hourglass_bottom, 300, 80, 1),
        _buildFloatingIcon(Icons.timer, 80, 350, 2),
        _buildFloatingIcon(Icons.access_time, 320, 450, 3),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, double left, double top, int index) {
    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: (value * 2 * math.pi) / 8,
            child: Opacity(
              opacity: 0.15 + (0.1 * value),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingIllustration() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Transform.rotate(
          angle: math.sin(_waveController.value * 2 * math.pi) * 0.1,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Lottie.asset(
                    'assets/animations/hourglass.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
                        size: 80,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox('1-2', 'Hari'),
              const SizedBox(width: 12),
              const Text(
                '⏰',
                style: TextStyle(
                  fontSize: 24,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 12),
              _buildTimeBox('24', 'Jam'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Estimasi Waktu Verifikasi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.totalCount - widget.pendingCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Selesai',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.pending_actions, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.pendingCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Anda akan menerima notifikasi saat verifikasi selesai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          DocumentStatusHelper.navigateToStatus(context, 'crew');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment, size: 20, color: Color(0xFFFB8C00)),
            SizedBox(width: 8),
            Text(
              'Lihat Status Detail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFB8C00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SandTimerPainter extends CustomPainter {
  final double animationValue;

  SandTimerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Draw sand falling effect
    for (int i = 0; i < 15; i++) {
      final x = (i * 40.0) % size.width;
      final y = (animationValue * size.height + i * 50) % size.height;
      final radius = 2.0 + (i % 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(SandTimerPainter oldDelegate) => true;
}