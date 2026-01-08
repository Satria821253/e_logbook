import 'package:flutter/material.dart';
import 'package:e_logbook/utils/responsive_helper.dart';

class AppInfo extends StatelessWidget {
  final String version;
  final String releaseYear;

  const AppInfo({
    super.key,
    required this.version,
    required this.releaseYear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
        Text(
          "V $version",
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16), 
            color: Color.fromARGB(255, 129, 129, 129),
          ),
        ),

        SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6)),
        Text(
          "© $releaseYear E-Logbook",
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14), 
            color: Color.fromARGB(255, 129, 129, 129),
          ),
        ),
      ],
    );
  }
}
