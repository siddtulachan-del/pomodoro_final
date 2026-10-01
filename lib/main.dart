import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.load();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightTextTheme = GoogleFonts.dmSansTextTheme(
      ThemeData.light(useMaterial3: true).textTheme,
    );
    final darkTextTheme = GoogleFonts.dmSansTextTheme(
      ThemeData.dark(useMaterial3: true).textTheme,
    );
    const lightPrimary = Color.fromARGB(255, 205, 56, 30);
    const darkPrimary = Color(0xFFFF7A62);

    TextTheme buildHeadlineTheme(TextTheme base) {
      return base.copyWith(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.headlineLarge,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.headlineMedium,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.headlineSmall,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          textStyle: base.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.bricolageGrotesque(
          textStyle: base.titleMedium,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.bricolageGrotesque(
          textStyle: base.titleSmall,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      );
    }

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pomodoro',
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: lightPrimary,
              brightness: Brightness.light,
            ).copyWith(primary: lightPrimary),
            textTheme: buildHeadlineTheme(lightTextTheme),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: darkPrimary,
                  brightness: Brightness.dark,
                ).copyWith(
                  primary: darkPrimary,
                  primaryContainer: const Color(0xFF2B2B2B),
                  onPrimaryContainer: const Color(0xFFF1F1F1),
                  secondary: const Color(0xFFB9C1BE),
                  secondaryContainer: const Color(0xFF303030),
                  onSecondaryContainer: const Color(0xFFE6E6E6),
                  tertiary: const Color(0xFF7FC8B1),
                  tertiaryContainer: const Color(0xFF244036),
                  onTertiaryContainer: const Color(0xFFCCE8DD),
                  surface: const Color(0xFF121212),
                  surfaceContainerLowest: const Color(0xFF0D0D0D),
                  surfaceContainerLow: const Color(0xFF1A1A1A),
                  surfaceContainer: const Color(0xFF1E1E1E),
                  surfaceContainerHigh: const Color(0xFF262626),
                  surfaceContainerHighest: const Color(0xFF303030),
                  onSurface: const Color(0xFFE8E8E8),
                  onSurfaceVariant: const Color(0xFFC2C2C2),
                  outlineVariant: const Color(0xFF484848),
                ),
            textTheme: buildHeadlineTheme(darkTextTheme),
          ),
          themeMode: _appState.materialThemeMode,
          home: MyHomePage(appState: _appState),
        );
      },
    );
  }
}
