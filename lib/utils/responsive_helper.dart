import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;
  
  // Device type detection
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }
  
  // Responsive values with validation
  static double responsiveWidth(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 0) return mobile.w; // Fallback for invalid screen size
    
    if (isDesktop(context)) return (desktop ?? tablet ?? mobile).w;
    if (isTablet(context)) return (tablet ?? mobile).w;
    return mobile.w;
  }
  
  static double responsiveHeight(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0) return mobile.h; // Fallback for invalid screen size
    
    if (isDesktop(context)) return (desktop ?? tablet ?? mobile).h;
    if (isTablet(context)) return (tablet ?? mobile).h;
    return mobile.h;
  }
  
  static double responsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 0) return mobile.sp; // Fallback for invalid screen size
    
    if (isDesktop(context)) return (desktop ?? tablet ?? mobile).sp;
    if (isTablet(context)) return (tablet ?? mobile).sp;
    return mobile.sp;
  }
  
  // Container constraints for centering content on larger screens
  static BoxConstraints getContentConstraints(BuildContext context) {
    if (isTablet(context)) {
      return const BoxConstraints(maxWidth: 500);
    }
    return const BoxConstraints();
  }
  
  // Padding helpers
  static EdgeInsets responsivePadding(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = responsiveWidth(context, 
      mobile: mobile, 
      tablet: tablet, 
      desktop: desktop
    );
    return EdgeInsets.all(value);
  }
  
  static EdgeInsets responsiveHorizontalPadding(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = responsiveWidth(context, 
      mobile: mobile, 
      tablet: tablet, 
      desktop: desktop
    );
    return EdgeInsets.symmetric(horizontal: value);
  }
  
  static EdgeInsets responsiveVerticalPadding(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = responsiveHeight(context, 
      mobile: mobile, 
      tablet: tablet, 
      desktop: desktop
    );
    return EdgeInsets.symmetric(vertical: value);
  }
}