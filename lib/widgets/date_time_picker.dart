import 'package:flutter/material.dart';

class DateTimePickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const DateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B4F9C), size: fs(18)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sp(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sp(12)),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: sp(12),
            vertical: sp(12),
          ),
        ),
        child: Text(value, style: TextStyle(fontSize: fs(14))),
      ),
    );
  }
}