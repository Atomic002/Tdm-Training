import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/home_srceen.dart';
import 'package:flutter_application_1/screens/no_connection_screen.dart';

import 'package:flutter_application_1/services/admob_service.dart';
import 'package:flutter_application_1/utils/app_colors.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize AdMob with error handling
  try {
    await AdMobService.initialize();
    print('AdMob initialized successfully in main.dart');
  } catch (e) {
    print('AdMob initialization failed: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _hasInternet; // Null indicates loading state
  late StreamSubscription<InternetConnectionStatus> _listener;
  final InternetConnectionChecker _checker =
      InternetConnectionChecker.createInstance();

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _startMonitoring();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final connected = await _checker.hasConnection;
      if (mounted) {
        setState(() {
          _hasInternet = connected;
        });
      }
    } catch (e) {
      print('Error checking initial connection: $e');
      if (mounted) {
        setState(() {
          _hasInternet = false;
        });
      }
    }
  }

  void _startMonitoring() {
    _listener = _checker.onStatusChange.listen((status) {
      final connected = status == InternetConnectionStatus.connected;
      if (mounted && connected != _hasInternet) {
        setState(() {
          _hasInternet = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowMaterialGrid: false,
      title: 'PUBG TDM Training',
      debugShowCheckedModeBanner: false, // Set to false for production
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: _hasInternet == null
          ? const _LoadingScreen()
          : _hasInternet!
          ? const HomeScreen()
          : NoInternetScreen(onRetry: _checkInitialConnection),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Yuklanmoqda...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
