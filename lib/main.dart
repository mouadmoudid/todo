import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Set the language for Firebase Auth emails to use the device's locale
  await FirebaseAuth.instance.setLanguageCode(null);
  await SettingsService().init();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = _settings.settings;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      // Modern Material 3 theming — use a seed color from settings
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light).primary,
          foregroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light).onPrimary,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light).surfaceVariant.withOpacity(0.6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light).primaryContainer,
          labelStyle: const TextStyle(color: Colors.black87),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        // cardTheme: use default Card styling for Material 3
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.light).secondary,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark).surface,
          foregroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark).onSurface,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark).surfaceVariant.withOpacity(0.12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark).primaryContainer,
          labelStyle: const TextStyle(color: Colors.white70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        // cardTheme: use default Card styling for Material 3
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: ColorScheme.fromSeed(seedColor: s.primaryColor, brightness: Brightness.dark).secondary,
        ),
      ),
      themeMode: s.themeMode,
      builder: (context, child) {
        // Apply global text scale factor from settings
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: s.textScaleFactor),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LoginPage(),
    );
  }
}
