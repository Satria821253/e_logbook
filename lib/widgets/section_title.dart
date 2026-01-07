import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: color ?? const Color(0xFF1B4F9C),
            size: fs(22),
          ),
          SizedBox(width: sp(8)),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fs(18),
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF1B4F9C),
            ),
          ),
        ),
      ],
    );
  }
}