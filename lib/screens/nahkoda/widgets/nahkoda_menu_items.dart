import 'package:e_logbook/utils/responsive_helper.dart';
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
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 140, tablet: 180),
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
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 200, tablet: 264),
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
        // Data Raw
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 260, tablet: 348),
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
        // Info Trip
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 320, tablet: 432),
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
      ],
    );
  }
}