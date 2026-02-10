import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/zone_alert.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/config/app_initializer.dart';
import 'package:e_logbook/routes/route_generator.dart';
import 'package:e_logbook/screens/splash_screen.dart';
import 'package:e_logbook/widgets/initialization_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force orientation based on device type immediately
  await _setInitialOrientation();

  final initialized = await AppInitializer.initialize();

  runApp(
    initialized
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => UserProvider()),
              ChangeNotifierProvider(create: (_) => CatchProvider()),
              ChangeNotifierProvider(create: (_) => ZoneAlertProvider()),
              ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ],
            child: const MyApp(),
          )
        : const InitializationErrorScreen(),
  );
}

Future<void> _setInitialOrientation() async {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;
    final diagonalInches = _calculateDiagonalInches(shortestSide, longestSide);
    
    // Deteksi tablet: diagonal >= 7 inch ATAU shortestSide >= 600
    final isTablet = diagonalInches >= 7.0 || shortestSide >= 600;

    debugPrint('📱 Device Info:');
    debugPrint('   Shortest: ${shortestSide.toStringAsFixed(1)}');
    debugPrint('   Longest: ${longestSide.toStringAsFixed(1)}');
    debugPrint('   Diagonal: ${diagonalInches.toStringAsFixed(1)}"');
    debugPrint('   Type: ${isTablet ? "TABLET" : "PHONE"}');

    if (isTablet) {
      // Tablet → Landscape ONLY
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('✅ Tablet - Locked to LANDSCAPE');
    } else {
      // Phone → Portrait ONLY
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('✅ Phone - Locked to PORTRAIT');
    }
  } catch (e) {
    debugPrint('❌ Orientation setting failed: $e');
  }
}

double _calculateDiagonalInches(double width, double height) {
  const dpi = 160.0;
  final widthInches = width / dpi;
  final heightInches = height / dpi;
  return sqrt(widthInches * widthInches + heightInches * heightInches);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _orientationLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_orientationLocked) {
      _lockOrientation();
      _orientationLocked = true;
    }
  }

  void _lockOrientation() {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;
    final diagonalInches = _calculateDiagonalInches(shortestSide, longestSide);
    
    final isTablet = diagonalInches >= 7.0 || shortestSide >= 600;

    debugPrint('🔒 Locking orientation: ${isTablet ? "LANDSCAPE" : "PORTRAIT"}');

    if (isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const SplashScreen(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
