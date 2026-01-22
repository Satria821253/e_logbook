// lib/screens/documents/nahkoda_pending_popup.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class NahkodaPendingPopup extends StatefulWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int totalCount;

  const NahkodaPendingPopup({
    Key? key,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.totalCount = 8,
  }) : super(key: key);

  @override
  State<NahkodaPendingPopup> createState() => _NahkodaPendingPopupState();
}

class _NahkodaPendingPopupState extends State<NahkodaPendingPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
    _rotateController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
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
        _shakeController.forward(from: 0);
        return false;
      },
      child: GestureDetector(
        onTap: () => _shakeController.forward(from: 0),
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
                          Icons.pending,
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
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _shakeAnimation.value,
                    child: child,
                  );
                },
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0.02, end: 0.0).animate(_rotateAnimation),
                    child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
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
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPopupContent() {
    // Ubah warna jika ada rejected
    final hasRejected = widget.rejectedCount > 0;
    final gradientColors = hasRejected
        ? [
            Color(0xFFDC2626), // Merah tua
            Color(0xFFEF4444), // Merah
            Color(0xFFF87171), // Merah muda
          ]
        : [
            Color(0xFFFFA726),
            Color(0xFFFB8C00),
            Color(0xFFF57C00),
          ];
    
    return Container(
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Clock pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: ClockPatternPainter(),
            ),
          ),

          // Floating icons - REMOVED

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
                        'Dokumen Sedang Diverifikasi',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Admin sedang memeriksa ${widget.pendingCount} dokumen Anda',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildProgressInfo(),
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
                Icon(Icons.sailing, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'NAHKODA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
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


  Widget _buildPendingIllustration() {
    return ScaleTransition(
      scale: _pulseAnimation,
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
                'assets/animations/pending.json',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.pending_actions,
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
  }

  Widget _buildProgressInfo() {
    final progress = widget.approvedCount / widget.totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Verifikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.approvedCount} Disetujui',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '${widget.pendingCount} Menunggu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/document-status');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFFB8C00),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.visibility, size: 20),
            SizedBox(width: 8),
            Text(
              'Lihat Detail Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClockPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw clock circles
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3 + (i * 60)),
        20 + (i * 10),
        paint,
      );
    }

    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.6 + (i * 80)),
        25 + (i * 15),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}