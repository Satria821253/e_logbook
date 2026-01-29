import 'package:flutter/material.dart';
import 'package:e_logbook/routes/app_routes.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/screens/profile_screen.dart';
import 'package:e_logbook/screens/tracking/pre_trip_fromscreen.dart';
import 'package:e_logbook/screens/vessel/vessel_info_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_documents_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_bbm_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_ice_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_certificates_screen.dart';
import 'package:e_logbook/screens/vessel/fuel_management_screen.dart';
import 'package:e_logbook/screens/vessel/edit_fuel_screen.dart';
import 'package:e_logbook/screens/documents/document_status_helper.dart';
import 'package:e_logbook/screens/documents/document_upload_stepper.dart';
import 'package:e_logbook/screens/documents/nahkoda/nahkoda_document_status_screen.dart';
import 'package:e_logbook/screens/documents/crew/crew_document_status_screen.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/crew/screens/catch_detail_screen.dart';
import 'package:e_logbook/screens/vessel/certificates/certificate_stepper_screen.dart';
import 'package:e_logbook/screens/vessel/ice_management_screen.dart';
import 'package:e_logbook/screens/notification_detail_screen.dart';
import 'package:e_logbook/screens/zone_violation_detail_screen.dart';
import 'package:e_logbook/screens/page/edit_profile_screen.dart';

class RouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // Helper untuk membuat route tanpa transisi
    Route<T> _noTransitionRoute<T>(Widget page) {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    switch (settings.name) {
      case AppRoutes.home:
        return _noTransitionRoute(const MainScreen());
      
      case AppRoutes.profile:
        return _noTransitionRoute(const ProfileScreen());
      
      case AppRoutes.preTripForm:
        final tripData = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          PreTripFormScreen(tripData: tripData),
        );
      
      case AppRoutes.vesselInfo:
        final arguments = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          VesselInfoScreen(arguments: arguments),
        );
      
      case AppRoutes.vesselDocuments:
        return _noTransitionRoute(
          const VesselDocumentsScreen(),
        );
      
      case AppRoutes.documentCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
          ),
        );
      
      case AppRoutes.nahkodaDocumentUpload:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
            fromVesselDocs: args?['fromVesselDocs'] ?? false,
          ),
        );
      
      case AppRoutes.crewDocumentUpload:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          DocumentUploadStepper(
            rejectedDocType: args?['rejectedDocType'],
          ),
        );
      
      case AppRoutes.createCatch:
        return _noTransitionRoute(
          const CreateCatchScreen(),
        );
      
      case AppRoutes.documentStatus:
        return _noTransitionRoute(
          const DocumentStatusRoutes(),
        );
      
      case AppRoutes.nahkodaDocumentStatus:
        return _noTransitionRoute(
          const NahkodaDocumentStatusScreen(),
        );
      
      case AppRoutes.crewDocumentStatus:
        return _noTransitionRoute(
          const CrewDocumentStatusScreen(),
        );
      
      case AppRoutes.certificateUpload:
        return _noTransitionRoute(
          const CertificateStepperScreen(),
        );
      
      case AppRoutes.iceManagement:
        return _noTransitionRoute(
          const IceManagementScreen(),
        );
      
      case AppRoutes.vesselBBM:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          VesselBBMScreen(documentsData: args),
        );
      
      case AppRoutes.vesselIce:
        return _noTransitionRoute(
          const VesselIceScreen(),
        );
      
      case AppRoutes.fuelManagement:
        return _noTransitionRoute(
          const FuelManagementScreen(),
        );
      
      case AppRoutes.editFuel:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          EditFuelScreen(fuelData: args ?? {}),
        );
      
      case AppRoutes.catchDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          CatchDetailScreen(catchData: args?['catchData']),
        );
      
      case AppRoutes.notificationDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          NotificationDetailScreen(
            title: args?['title'] ?? '',
            message: args?['message'] ?? '',
            timestamp: args?['timestamp'] ?? DateTime.now(),
          ),
        );
      
      case AppRoutes.zoneViolationDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          ZoneViolationDetailScreen(
            zoneInfo: args?['zoneInfo'] ?? {},
            onDismiss: args?['onDismiss'] ?? () {},
          ),
        );
      
      case AppRoutes.editProfile:
        return _noTransitionRoute(
          const EditProfileScreen(),
        );
      
      case '/vessel-certificates':
        final args = settings.arguments as Map<String, dynamic>?;
        return _noTransitionRoute(
          VesselCertificatesScreen(
            documentsData: args?['documentsData'],
            vesselData: args?['vesselData'],
          ),
        );
      
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Halaman tidak ditemukan')),
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
