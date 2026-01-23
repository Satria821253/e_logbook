import 'package:flutter/material.dart';
import 'package:e_logbook/routes/app_routes.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/screens/profile_screen.dart';
import 'package:e_logbook/screens/tracking/pre_trip_fromscreen.dart';
import 'package:e_logbook/screens/vessel/vessel_info_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_documents_screen.dart';
import 'package:e_logbook/screens/documents/document_status_helper.dart';
import 'package:e_logbook/screens/documents/document_upload_stepper.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/vessel/certificate_upload_screen.dart';

class RouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case AppRoutes.preTripForm:
        final tripData = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PreTripFormScreen(tripData: tripData),
        );
      
      case AppRoutes.vesselInfo:
        final arguments = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VesselInfoScreen(arguments: arguments),
        );
      
      case AppRoutes.vesselDocuments:
        return MaterialPageRoute(
          builder: (_) => const VesselDocumentsScreen(),
        );
      
      case AppRoutes.documentCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
          ),
        );
      
      case AppRoutes.nahkodaDocumentUpload:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
            fromVesselDocs: args?['fromVesselDocs'] ?? false,
          ),
        );
      
      case AppRoutes.crewDocumentUpload:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
          ),
        );
      
      case AppRoutes.createCatch:
        return MaterialPageRoute(
          builder: (_) => const CreateCatchScreen(),
        );
      
      case AppRoutes.documentStatus:
        return MaterialPageRoute(
          builder: (_) => const DocumentStatusRoutes(),
        );
      
      case AppRoutes.certificateUpload:
        return MaterialPageRoute(
          builder: (_) => const CertificateUploadScreen(),
        );
      
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Halaman tidak ditemukan')),
      ),
    );
  }
}
