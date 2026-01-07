import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmergencyButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const EmergencyButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Lottie.asset(
          'assets/animations/alert.json',
          repeat: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
