import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_store_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/download_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStoreProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AppHub',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.flutterThemeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2D5BE3),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: const CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2D5BE3),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: const CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
