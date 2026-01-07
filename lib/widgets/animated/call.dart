import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedReportButton extends StatelessWidget {
  const AnimatedReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Aksi ketika tombol ditekan
      },
      child: Lottie.asset(
        'assets/animations/call.json',
        width: 115,
        height: 115,
        fit: BoxFit.contain,
        repeat: true, // true = berulang, false = sekali main
        animate: true,
      ),
    );
  }
}
