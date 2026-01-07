import 'package:flutter/material.dart';
import '../screens/nahkoda/screens/crew_attendance_screen.dart';
import '../screens/nahkoda/screens/trip_info_screen.dart';
import '../screens/crew/screens/data_raw_screen.dart';
import 'tracking_routes.dart';


class NahkodaRoutes {
  static void navigateToTripInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TripInfoScreen(),
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

  static void navigateToCrewAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrewAttendanceScreen(),
      ),
    );
  }

  static void navigateToTracking(BuildContext context) {
    TrackingRoutes.navigateToPreTripForm(context);
  }

  static void showEmergencyDialog(BuildContext context) {
    TrackingRoutes.showTrackingEmergencyDialog(context);
  }
}