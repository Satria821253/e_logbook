import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final bool readOnly;
  final Function(String)? onChanged;
  final Widget? suffixWidget;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.required = true,
    this.readOnly = false,
    this.onChanged,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon, 
          color: const Color(0xFF1B4F9C), 
          size: ResponsiveHelper.responsiveWidth(context, mobile: 18, tablet: 22),
        ),
        suffixIcon: suffixWidget,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          borderSide: BorderSide(
            color: const Color(0xFF1B4F9C), 
            width: ResponsiveHelper.responsiveWidth(context, mobile: 2, tablet: 3),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          borderSide: BorderSide(
            color: Colors.red, 
            width: ResponsiveHelper.responsiveWidth(context, mobile: 1, tablet: 2),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          vertical: ResponsiveHelper.responsiveHeight(context, mobile: 12, tablet: 16),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Field ini harus diisi';
              }
              return null;
            }
          : null,
    );
  }
}