import 'dart:async';
import 'package:flutter/material.dart';
import 'package:e_logbook/utils/responsive_helper.dart';

class CatchCarousel extends StatefulWidget {
  const CatchCarousel({super.key});

  @override
  State<CatchCarousel> createState() => _CatchCarouselState();
}

class _CatchCarouselState extends State<CatchCarousel> {
  final PageController _controller = PageController(
    viewportFraction: 0.94,
    initialPage: 1000, // Mulai dari tengah untuk infinite scroll
  );
  Timer? _timer;
  int _currentPage = 0;
  double _currentPageValue = 0.0;

  final List<String> dummyImages = [
    'assets/fish.jpeg',
    'assets/fish1.jpg',
    'assets/fish2.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue = _controller.page ?? 0.0;
          // Update current page berdasarkan modulo
          _currentPage = (_controller.page?.round() ?? 0) % dummyImages.length;
        });
      }
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      final nextPage = (_controller.page?.round() ?? 0) + 1;

      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dummyImages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: ResponsiveHelper.height(context, mobile: 240, tablet: 280),
          child: PageView.builder(
            controller: _controller,
            itemCount: null, // Infinite scroll
            onPageChanged: (i) {
              setState(() {
                _currentPage = i % dummyImages.length;
              });
            },
            itemBuilder: (context, index) {
              // Gunakan modulo untuk loop gambar
              final imageIndex = index % dummyImages.length;
              
              // Perhitungan scale effect
              double scale = 1.0;
              if (_currentPageValue >= index - 1 && _currentPageValue <= index + 1) {
                scale = 1.0 - ((_currentPageValue - index).abs() * 0.1);
              }

              return Transform.scale(
                scale: scale,
                child: AnimatedOpacity(
                  opacity: _currentPage == imageIndex ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.width(context, mobile: 6, tablet: 8),
                      vertical: ResponsiveHelper.height(context, mobile: 12, tablet: 16),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.width(context, mobile: 24, tablet: 28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: ResponsiveHelper.width(context, mobile: 8, tablet: 12),
                          offset: Offset(0, ResponsiveHelper.height(context, mobile: 2, tablet: 3)),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.width(context, mobile: 24, tablet: 28)),
                      child: Stack(
                        children: [
                          Image.asset(
                            dummyImages[imageIndex],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // Gradient overlay untuk efek depth
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        SizedBox(height: ResponsiveHelper.height(context, mobile: 12, tablet: 16)),
        
        // Dot indicators dengan animasi
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            dummyImages.length,
            (index) {
              bool isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.width(context, mobile: 4, tablet: 6)),
                height: ResponsiveHelper.height(context, mobile: 8, tablet: 10),
                width: isActive 
                    ? ResponsiveHelper.width(context, mobile: 24, tablet: 28)
                    : ResponsiveHelper.width(context, mobile: 8, tablet: 10),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.width(context, mobile: 4, tablet: 5)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}