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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: s.primaryColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: s.primaryColor,
        brightness: Brightness.dark,
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
