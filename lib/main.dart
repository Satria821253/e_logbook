import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/zone_alert.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/config/app_initializer.dart';
import 'package:e_logbook/routes/route_generator.dart';
import 'package:e_logbook/screens/splash_screen.dart';
import 'package:e_logbook/widgets/initialization_error_screen.dart';
import 'package:e_logbook/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
            child: const ErrorBoundary(child: MyApp()),
          )
        : const InitializationErrorScreen(),
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
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}
