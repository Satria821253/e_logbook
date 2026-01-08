import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/zone_alert.dart';
import 'package:e_logbook/services/auth_service.dart';
import 'package:e_logbook/services/data_clear_service.dart';
import 'package:e_logbook/services/offline_sync_service.dart';
import 'package:e_logbook/screens/profile_screen.dart';
import 'package:e_logbook/screens/tracking/pre_trip_fromscreen.dart';
import 'package:e_logbook/screens/vessel_info_screen.dart';
import 'package:e_logbook/screens/document_completion_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  try {
    AuthService.init();

    // Clear all dummy data on app start (fresh start every time)
    await DataClearService.clearAllDummyData();

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
                return MaterialPageRoute(builder: (_) => VesselInfoScreen(arguments: arguments));
              case '/document-completion':
                final arguments = settings.arguments as String?;
                return MaterialPageRoute(builder: (_) => DocumentCompletionScreen(), settings: RouteSettings(arguments: arguments));
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
