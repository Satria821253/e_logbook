// lib/screens/documents/document_status_helper.dart

import 'package:flutter/material.dart';
import 'nahkoda/nahkoda_document_status_screen.dart';
import '../document_status_screen.dart';

class DocumentStatusHelper {
  /// Navigate to document status screen based on user role
  static void navigateToStatus(BuildContext context, String userRole) {
    Widget screen;

    if (userRole.toLowerCase() == 'nahkoda' || 
        userRole.toLowerCase() == 'captain') {
      screen = const NahkodaDocumentStatusScreen();
    } else {
      // ABK, Crew, or any other role - use generic document status screen
      screen = const DocumentStatusScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Show status as bottom sheet (alternative)
  static void showStatusBottomSheet(BuildContext context, String userRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          child: userRole.toLowerCase() == 'nahkoda' || 
                 userRole.toLowerCase() == 'captain'
              ? const NahkodaDocumentStatusScreen()
              : const DocumentStatusScreen(),
        );
      },
    );
  }
}
