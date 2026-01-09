import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'menu_toggle_button.dart';
import 'nahkoda_menu_items.dart';

class NahkodaFloatingMenu extends StatefulWidget {
  const NahkodaFloatingMenu({super.key});

  @override
  State<NahkodaFloatingMenu> createState() => _NahkodaFloatingMenuState();
}

class _NahkodaFloatingMenuState extends State<NahkodaFloatingMenu>
    with TickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    if (_isMenuOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: ResponsiveHelper.width(context, mobile: 28, tablet: 32),
          bottom: ResponsiveHelper.height(context, mobile: 80, tablet: 96),
          child: MenuToggleButton(
            isMenuOpen: _isMenuOpen,
            onToggle: _toggleMenu,
          ),
        ),
        if (_isMenuOpen)
          NahkodaMenuItems(
            animation: _animation,
            onMenuToggle: _toggleMenu,
          ),
      ],
    );
  }
}