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
        // Customer Service (WhatsApp)
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 230, tablet: 290),
          child: ScaleTransition(
            scale: animation,
            child: CrewFloatingActionButton(
              icon: Icons.support_agent,
              color: Colors.blue,
              onTap: () {
                onMenuToggle();
                CrewRoutes.navigateToCustomerService(context);
              },
            ),
          ),
        ),
        // Data Raw
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 300, tablet: 390),
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
        // Jadwal Tugas
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 370, tablet: 490),
          child: ScaleTransition(
            scale: animation,
            child: CrewFloatingActionButton(
              icon: Icons.calendar_today,
              color: Colors.purple,
              onTap: () {
                onMenuToggle();
                CrewRoutes.navigateToMySchedules(context);
              },
            ),
          ),
        ),
        // Riwayat Tugas Saya
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 440, tablet: 590),
          child: ScaleTransition(
            scale: animation,
            child: CrewFloatingActionButton(
              icon: Icons.history,
              color: Colors.teal,
              onTap: () {
                onMenuToggle();
                CrewRoutes.navigateToMyTripsHistory(context);
              },
            ),
          ),
        ),
      ],
    );
  }
}