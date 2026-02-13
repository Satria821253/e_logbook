import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/provider/tracking_minimize_provider.dart';
import 'package:e_logbook/screens/tracking/production_map.dart';

class TrackingMinimizedOverlay extends StatefulWidget {
  const TrackingMinimizedOverlay({super.key});

  @override
  State<TrackingMinimizedOverlay> createState() => _TrackingMinimizedOverlayState();
}

class _TrackingMinimizedOverlayState extends State<TrackingMinimizedOverlay> with SingleTickerProviderStateMixin {
  Offset? _position;
  Offset? _dragPosition;
  bool _showControls = false;
  late AnimationController _snapController;


  @override
  void initState() {
    super.initState();
    print('🟢 [Minimize Widget] initState called - Widget created');
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    print('🔴 [Minimize Widget] dispose called - Widget destroyed');
    _snapController.dispose();
    super.dispose();
  }

  Offset _getInitialPosition(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Offset(16, screenHeight - 180 - 80); // Kiri bawah
  }

  Offset _snapToCorner(Offset position, Size screenSize) {
    final centerX = position.dx + 70;
    final centerY = position.dy + 90;
    final isRight = centerX > screenSize.width / 2;
    final isBottom = centerY > screenSize.height / 2;

    final x = isRight ? screenSize.width - 140 - 16 : 16.0;
    final y = isBottom ? screenSize.height - 180 - 80 : 80.0;

    return Offset(x, y);
  }

  void _animateToCorner(Offset targetPosition) {
    setState(() {
      _position = targetPosition;
      _dragPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 [Minimize Widget] build called - Rebuilding widget');
    return Consumer<TrackingMinimizeProvider>(
      builder: (context, provider, child) {
        print('📊 [Minimize Widget] Consumer builder called');
        print('📊 [Minimize Widget] isMinimized: ${provider.isMinimized}');
        print('📊 [Minimize Widget] isTrackingActive: ${provider.isTrackingActive}');
        
        final trackingData = provider.trackingData;
        final currentPosition = provider.currentPosition;
        
        print('📊 [Minimize Widget] trackingData: ${trackingData != null}');
        print('📊 [Minimize Widget] currentPosition: ${currentPosition != null}');
        
        if (trackingData == null) {
          print('⚠️ [Minimize Widget] trackingData is null - returning empty widget');
          return const SizedBox.shrink();
        }

        final position = _dragPosition ?? _position ?? _getInitialPosition(context);

        return AnimatedPositioned(
          duration: _dragPosition != null ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onTap: () {
              print('👆 [Minimize Widget] Widget tapped - toggling controls');
              print('👆 [Minimize Widget] Current _showControls: $_showControls');
              setState(() => _showControls = !_showControls);
              print('👆 [Minimize Widget] New _showControls: $_showControls');
            },
            onPanStart: (details) {
              setState(() {
                _dragPosition = _position ?? _getInitialPosition(context);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _dragPosition = Offset(
                  (_dragPosition!.dx + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 140.0),
                  (_dragPosition!.dy + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 180.0),
                );
              });
            },
            onPanEnd: (details) {
              if (_dragPosition != null) {
                final targetPosition = _snapToCorner(_dragPosition!, MediaQuery.of(context).size);
                _animateToCorner(targetPosition);
              }
            },
            child: Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: currentPosition != null && trackingData['harborCoordinates'] != null
                        ? IgnorePointer(
                            child: ProductionTrackingMap(
                              currentPosition: currentPosition,
                              harborLat: trackingData['harborCoordinates']['lat'],
                              harborLng: trackingData['harborCoordinates']['lng'],
                              harborName: trackingData['selectedHarbor'] ?? '',
                              zoneRadius: trackingData['zoneRadius'] ?? 0.0,
                              isViolating: provider.isViolating,
                              selectedCatchZoneName: trackingData['selectedHarbor'] ?? '',
                              zoneStatus: provider.zoneStatus,
                              isMinimized: true,
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          ),
                  ),
                  if (_showControls)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                print('❌ [Minimize Widget] Close button tapped');
                                print('❌ [Minimize Widget] Calling stopTracking()');
                                provider.stopTracking();
                                print('❌ [Minimize Widget] stopTracking() completed');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                print('\n🔵🔵🔵 [Minimize] MAXIMIZE BUTTON TAPPED');
                                print('🔵 [Minimize] Hiding controls');
                                setState(() => _showControls = false);
                                
                                // Pop semua screen sampai kembali ke ActiveTrackingScreen
                                print('🔵 [Minimize] Popping to ActiveTrackingScreen...');
                                Navigator.of(context).popUntil((route) {
                                  // Cek apakah route ini adalah ActiveTrackingScreen
                                  final isActiveTracking = route.settings.name?.contains('ActiveTracking') ?? false;
                                  if (isActiveTracking) {
                                    print('🔵 [Minimize] Found ActiveTrackingScreen, stopping pop');
                                    return true;
                                  }
                                  // Cek apakah ini adalah route pertama (untuk menghindari pop semua)
                                  if (route.isFirst) {
                                    print('🔵 [Minimize] Reached first route, stopping pop');
                                    return true;
                                  }
                                  print('🔵 [Minimize] Popping route: ${route.settings.name}');
                                  return false;
                                });
                                
                                // Setelah pop, maximize
                                provider.maximize();
                                print('🔵 [Minimize] maximize() called - isMinimized now: ${provider.isMinimized}');
                                print('🔵🔵🔵 [Minimize] Should show ActiveTrackingScreen full view\n');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4F9C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.open_in_full,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
