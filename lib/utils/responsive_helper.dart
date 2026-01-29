import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet }

class ResponsiveHelper {
  // ======================
  // Breakpoints
  // ======================
  static const double tabletMin = 500; // Konsisten dengan splash screen
  static const double tabletMedium = 600; // iPad, Galaxy Tab
  static const double tabletLarge = 768; // iPad Pro, Galaxy Tab S8+

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
  // Tablet Size Detection (small, medium, large)
  // ======================
  static String tabletSize(BuildContext context) {
    if (!isTablet(context)) return 'mobile';
    
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    
    if (shortestSide >= tabletLarge) return 'large';   // iPad Pro, Galaxy Tab S8+
    if (shortestSide >= tabletMedium) return 'medium'; // iPad, Galaxy Tab
    return 'small'; // Tablet kecil 7-8 inch
  }

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
  // Adaptive Value (otomatis menyesuaikan dengan tablet size)
  // ======================
  static double adaptiveValue(
    BuildContext context, {
    required double mobile,
    double? smallTablet,
    double? mediumTablet,
    double? largeTablet,
    double? mobileLandscape,
  }) {
    final size = tabletSize(context);
    final landscape = isLandscape(context);

    if (size == 'mobile') {
      return landscape && mobileLandscape != null ? mobileLandscape : mobile;
    }

    // Tablet - pilih ukuran berdasarkan size
    if (landscape) {
      switch (size) {
        case 'large':
          return largeTablet ?? mediumTablet ?? smallTablet ?? mobile * 1.6;
        case 'medium':
          return mediumTablet ?? smallTablet ?? mobile * 1.4;
        case 'small':
          return smallTablet ?? mobile * 1.2;
        default:
          return mobile;
      }
    } else {
      // Portrait - ukuran lebih kecil
      return smallTablet ?? mobile * 1.1;
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
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
  }

  static double height(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
    double? tabletLandscape,
  }) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      mobileLandscape: mobileLandscape,
      tabletLandscape: tabletLandscape,
    );
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
    return val.clamp(min, max);
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
  // Login Screen Specific - Logo & Animation Size
  // ======================
  static double loginLogoSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? mobileLandscape,
  }) {
    return adaptiveValue(
      context,
      mobile: mobile,
      smallTablet: tablet ?? mobile * 1.2,
      mediumTablet: tablet ?? mobile * 1.3,
      largeTablet: tablet ?? mobile * 1.4,
      mobileLandscape: mobileLandscape ?? mobile * 0.6,
    );
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
          ? size.shortestSide * 0.7
          : size.shortestSide * 0.6;
    }

    return isLandscape(context)
        ? size.shortestSide * 0.8
        : double.infinity;
  }
}