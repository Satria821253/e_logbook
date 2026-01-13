import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class MenuToggleButton extends StatelessWidget {
  final bool isMenuOpen;
  final VoidCallback onToggle;

  const MenuToggleButton({
    super.key,
    required this.isMenuOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: ResponsiveHelper.width(context, mobile: 48, tablet: 64),
        height: ResponsiveHelper.height(context, mobile: 48, tablet: 64),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4F9C),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4F9C).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: isMenuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isMenuOpen ? Icons.close : Icons.menu,
            color: Colors.white,
            size: ResponsiveHelper.width(context, mobile: 24, tablet: 28),
          ),
        ),
      ),
    );
  }
}