import 'package:flutter/material.dart';
import '../../../routes/nahkoda_routes.dart';
import 'floating_action_button_widget.dart';

class NahkodaMenuItems extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onMenuToggle;

  const NahkodaMenuItems({
    super.key,
    required this.animation,
    required this.onMenuToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Emergency
        Positioned(
          right: 28,
          bottom: 150,
          child: ScaleTransition(
            scale: animation,
            child: FloatingActionButtonWidget(
              icon: Icons.emergency,
              color: Colors.red,
              onTap: () {
                onMenuToggle();
                NahkodaRoutes.showEmergencyDialog(context);
              },
            ),
          ),
        ),
        // Kehadiran Crew
        Positioned(
          right: 28,
          bottom: 220,
          child: ScaleTransition(
            scale: animation,
            child: FloatingActionButtonWidget(
              icon: Icons.assignment_ind_rounded,
              color: Colors.blue,
              onTap: () {
                onMenuToggle();
                NahkodaRoutes.navigateToCrewAttendance(context);
              },
            ),
          ),
        ),
        // Info Trip
        Positioned(
          right: 28,
          bottom: 360,
          child: ScaleTransition(
            scale: animation,
            child: FloatingActionButtonWidget(
              icon: Icons.info_outline,
              color: Colors.orange,
              onTap: () {
                onMenuToggle();
                NahkodaRoutes.navigateToTripInfo(context);
              },
            ),
          ),
        ),
        // Data Raw
        Positioned(
          right: 28,
          bottom: 290,
          child: ScaleTransition(
            scale: animation,
            child: FloatingActionButtonWidget(
              icon: Icons.analytics,
              color: Colors.green,
              onTap: () {
                onMenuToggle();
                NahkodaRoutes.navigateToDataRaw(context);
              },
            ),
          ),
        ),
      ],
    );
  }
}