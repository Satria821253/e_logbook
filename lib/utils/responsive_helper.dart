import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet }

class ResponsiveHelper {
  // ======================
  // Breakpoints
  // ======================
  static const double tabletMin = 600;

  // ======================
  // Device Type (berdasarkan dimensi terkecil untuk stabilitas orientasi)
  // ======================
  static DeviceType deviceType(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;

    if (shortestSide >= tabletMin) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  // ======================
  // Orientation Detection
  // ======================
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // ======================
  // Responsive Value Core dengan Orientation Support
  // ======================
  static double value(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final type = deviceType(context);
    final landscape = isLandscape(context);

    switch (type) {
      case DeviceType.tablet:
        if (landscape && tabletLandscape != null) return tabletLandscape;
        return tablet ?? mobile * 1.4;
      case DeviceType.mobile:
        if (landscape && mobileLandscape != null) return mobileLandscape;
        return mobile; // Gunakan ukuran mobile asli
    }
  }

  // ======================
  // Size Helpers - Menggunakan shortestSide untuk konsistensi
  // ======================
  static double width(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final val = value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    
    // Gunakan MediaQuery.textScaleFactor untuk konsistensi
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScaleFactorOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    
    // Normalisasi berdasarkan density
    final normalizedWidth = size.width / devicePixelRatio;
    final scaleFactor = (normalizedWidth / 375.0).clamp(0.8, 1.5);
    
    return val * scaleFactor / textScale;
  }

  static double height(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final val = value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScaleFactorOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    
    // Normalisasi berdasarkan density
    final normalizedHeight = size.height / devicePixelRatio;
    final scaleFactor = (normalizedHeight / 812.0).clamp(0.8, 1.5);
    
    return val * scaleFactor / textScale;
  }

  static double font(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
    double min = 10,
    double max = 40,
  }) {
    final val = value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    
    // Font size dengan normalisasi device pixel ratio
    final size = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final textScale = MediaQuery.textScaleFactorOf(context);
    
    final normalizedWidth = size.width / devicePixelRatio;
    final scaleFactor = (normalizedWidth / 375.0).clamp(0.85, 1.3);

    return (val * scaleFactor / textScale).clamp(min, max);
  }

  // ======================
  // Image/Widget Size Helper (proporsi terhadap screen)
  // ======================
  static double imageSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final val = value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    
    final size = MediaQuery.sizeOf(context);
    final baseSize = size.shortestSide;
    return (val / 375.0) * baseSize;
  }

  // ======================
  // Padding Helpers
  // ======================
  static EdgeInsets padding(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final v = width(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    return EdgeInsets.all(v);
  }

  static EdgeInsets paddingHorizontal(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final v = width(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    return EdgeInsets.symmetric(horizontal: v);
  }

  static EdgeInsets paddingVertical(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    final v = height(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
    return EdgeInsets.symmetric(vertical: v);
  }

  // ======================
  // Content Constraints
  // ======================
  static BoxConstraints contentConstraints(BuildContext context) {
    if (isTablet(context)) {
      return const BoxConstraints(maxWidth: 800);
    }
    return const BoxConstraints();
  }

  // ======================
  // Spacing Helper (lebih natural untuk spacing antar widget)
  // ======================
  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    return height(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.3,
      mobileLandscape: mobileLandscape ?? mobile * 0.6,
      tabletLandscape: tabletLandscape ?? (tablet ?? mobile * 1.3) * 0.7,
    );
  }
  
  static double buttonWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (isTablet(context)) {
      return isLandscape(context)
          ? size.shortestSide * 0.6
          : size.shortestSide * 0.7;
    }

    return isLandscape(context)
        ? size.shortestSide * 0.8
        : double.infinity;
  }
}