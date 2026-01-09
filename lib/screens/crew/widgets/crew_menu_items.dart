import 'package:e_logbook/utils/responsive_helper.dart';
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
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 150, tablet: 180),
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
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 220, tablet: 264),
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
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 290, tablet: 348),
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