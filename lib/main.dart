import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/zone_alert.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/services/getAPi/auth_service.dart';
import 'package:e_logbook/services/offline_sync_service.dart';
import 'package:e_logbook/screens/profile_screen.dart';
import 'package:e_logbook/screens/tracking/pre_trip_fromscreen.dart';
import 'package:e_logbook/screens/vessel_info_screen.dart';
import 'package:e_logbook/screens/document_completion_screen.dart';
import 'package:e_logbook/screens/document_status_screen.dart';
import 'package:e_logbook/screens/vessel_selection_screen.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Clear old corrupted photo URLs (one-time fix)
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && userData.contains('api10-')) {
      await prefs.remove('user_data');
      await prefs.remove('user_profile');
      debugPrint('🧹 Cleared corrupted cache');
    }
    
    AuthService.init();
    
    // Initialize Indonesian locale for date formatting
    await initializeDateFormatting('id_ID', null);

    // Start offline sync monitoring
    OfflineSyncService.startConnectivityMonitoring();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CatchProvider()),
        ChangeNotifierProvider(create: (_) => ZoneAlertProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      ensureScreenSize: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[50],
          ),
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const MainScreen());
              case '/profile':
                return MaterialPageRoute(builder: (_) => const ProfileScreen());
              case '/pre-trip-form':
                final tripData = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => PreTripFormScreen(tripData: tripData),
                );
              case '/vessel-info':
                final arguments = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => VesselInfoScreen(arguments: arguments),
                );
              case '/document-completion':
                final arguments = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => DocumentCompletionScreen(),
                  settings: RouteSettings(arguments: arguments),
                );
              case '/create-catch':
                return MaterialPageRoute(
                  builder: (_) => const CreateCatchScreen(),
                );
              case '/document-status':
                return MaterialPageRoute(
                  builder: (_) => const DocumentStatusScreen(),
                );
              case '/vessel-selection':
                return MaterialPageRoute(
                  builder: (_) => const VesselSelectionScreen(),
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
