import 'package:flutter/material.dart';
import '../screens/crew/screens/abk_attendance_mark_screen.dart';
import '../screens/crew/screens/data_raw_screen.dart';
import '../screens/crew/screens/fish_photo_tips_screen.dart';
import 'common_routes.dart';

class CrewRoutes {
  static void navigateToMarkAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ABKAttendanceMarkScreen(),
      ),
    );
  }

  static void navigateToDataRaw(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DataRawScreen(),
      ),
    );
  }

  static void navigateToFishPhotoTips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FishPhotoTipsScreen(),
      ),
    );
  }

  static void navigateToRegistration(BuildContext context) {
    CommonRoutes.showInfoSnackBar(
      context, 
      'Pendaftaran crew dilakukan melalui web'
    );
  }

  static void showEmergencyDialog(BuildContext context) {
    CommonRoutes.showInfoSnackBar(
      context, 
      'Fitur emergency akan segera tersedia'
    );
  }
}