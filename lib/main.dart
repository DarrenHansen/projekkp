import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/business_profile_provider.dart';
import 'providers/locale_provider.dart';

import 'utils/app_localizations.dart';
import 'utils/notification_helper.dart';

import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';

/// Check first app launch
Future<bool> isFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();

  final hasOpened = prefs.getBool('has_opened_app') ?? false;

  if (!hasOpened) {
    await prefs.setBool('has_opened_app', true);
    return true;
  }

  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Check onboarding state
  final firstLaunch = await isFirstLaunch();

  /// Initialize notifications
  await NotificationHelper.initialize();
  await NotificationHelper.requestPermissions();

  /// Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  /// Lock portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProfileProvider()),
      ],
      child: MyApp(firstLaunch: firstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firstLaunch;

  const MyApp({
    super.key,
    required this.firstLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Fasnota',
      debugShowCheckedModeBanner: false,

      /// Theme
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode:
          themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      /// Localization
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      /// First launch logic
      home: firstLaunch
          ? const WelcomeScreen()
          : const MainNavigationScreen(),

      /// Prevent system font scaling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}