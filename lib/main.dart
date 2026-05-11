import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/invoice_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations (portrait only for mobile-first)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Invoice App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Routes
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/invoices': (context) => const InvoiceListScreen(),
            '/settings': (context) => const SettingsScreen(),
          },

          // Route untuk detail invoice (perlu pass argument)
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/invoice-detail':
                final invoice = settings.arguments;
                if (invoice != null) {
                  return MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(
                      invoice: invoice as dynamic,
                    ),
                  );
                }
                return null;
              default:
                return null;
            }
          },

          // Builder untuk animasi route global
          builder: (context, child) {
            return MediaQuery(
              // Disable text scaling untuk layout konsisten
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
