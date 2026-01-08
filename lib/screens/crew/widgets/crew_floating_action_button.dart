import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CrewFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CrewFloatingActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String? lottieAsset;
    bool useLottie = false;
    
    switch (icon) {
      case Icons.emergency:
        lottieAsset = 'assets/animations/call.json';
        useLottie = true;
        break;
      case Icons.my_location:
        final now = DateTime.now();
        final isNight = now.hour >= 18 || now.hour < 6;
        lottieAsset = isNight 
            ? 'assets/animations/tripmalam.json'
            : 'assets/animations/tripsiang.json';
        useLottie = true;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ResponsiveHelper.responsiveWidth(context, mobile: 56, tablet: 64),
        height: ResponsiveHelper.responsiveHeight(context, mobile: 56, tablet: 64),
        decoration: BoxDecoration(
          color: useLottie ? Colors.white : color,
          shape: BoxShape.circle,
          border: useLottie ? Border.all(color: color, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(useLottie ? 0.4 : 0.3),
              blurRadius: useLottie ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: useLottie
            ? ClipOval(
                child: Lottie.asset(
                  lottieAsset!,
                  fit: BoxFit.cover,
                  repeat: true,
                  animate: true,
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28),
              ),
      ),
    );
  }
}