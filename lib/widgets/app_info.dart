import 'package:flutter/material.dart';

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
        const SizedBox(height: 8),
        Text(
          "V $version",
          style: const TextStyle(
            fontSize: 14, color: Color.fromARGB(255, 129, 129, 129),),
        ),

        const SizedBox(height: 4),
        Text(
          "© $releaseYear E-Logbook",
          style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 129, 129, 129),),
        ),
      ],
    );
  }
}
