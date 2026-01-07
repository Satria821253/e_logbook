import 'package:flutter/material.dart';
import '../../../routes/crew_routes.dart';
import 'crew_floating_action_button.dart';

class CrewMenuItems extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onMenuToggle;

  const CrewMenuItems({
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
            child: CrewFloatingActionButton(
              icon: Icons.emergency,
              color: Colors.red,
              onTap: () {
                onMenuToggle();
                CrewRoutes.showEmergencyDialog(context);
              },
            ),
          ),
        ),
        // Daftar Hadir
        Positioned(
          right: 28,
          bottom: 220,
          child: ScaleTransition(
            scale: animation,
            child: CrewFloatingActionButton(
              icon: Icons.check_circle_outline,
              color: Colors.orange,
              onTap: () {
                onMenuToggle();
                CrewRoutes.navigateToMarkAttendance(context);
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
            child: CrewFloatingActionButton(
              icon: Icons.storage,
              color: Colors.green,
              onTap: () {
                onMenuToggle();
                CrewRoutes.navigateToDataRaw(context);
              },
            ),
          ),
        ),
      ],
    );
  }
}