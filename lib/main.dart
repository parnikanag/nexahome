import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartHomeTwinApp());
}

class SmartHomeTwinApp extends StatefulWidget {
  const SmartHomeTwinApp({super.key});
  @override
  State<SmartHomeTwinApp> createState() => _SmartHomeTwinAppState();
}

class _SmartHomeTwinAppState extends State<SmartHomeTwinApp> {
  late final AppController controller = AppController();
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NexaHome',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF080D18),
          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF65D9C4),
            onPrimary: Color(0xFF06201D),
            secondary: Color(0xFF91B9FF),
            onSecondary: Color(0xFF0A1930),
            error: Color(0xFFFF8C86),
            onError: Color(0xFF2A0807),
            surface: Color(0xFF101A29),
            onSurface: Color(0xFFE9F0F8),
            surfaceContainerHighest: Color(0xFF1A2738),
            onSurfaceVariant: Color(0xFFA8B8CB),
            outline: Color(0xFF344258),
            outlineVariant: Color(0xFF263449),
            shadow: Color(0xFF000000),
            scrim: Color(0xCC000000),
            inverseSurface: Color(0xFFE9F0F8),
            onInverseSurface: Color(0xFF101A29),
            inversePrimary: Color(0xFF197A6B),
            surfaceTint: Color(0xFF65D9C4),
          ),
          dividerColor: const Color(0xFF263449),
          visualDensity: VisualDensity.standard,
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
            titleLarge: TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: -.2,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -.1,
            ),
            bodyLarge: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFFE0E8F2),
            ),
            bodyMedium: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFFC0CDDC),
            ),
            labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF0B1422),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF344258)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF29384D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF65D9C4),
                width: 1.5,
              ),
            ),
            labelStyle: const TextStyle(color: Color(0xFFA8B8CB)),
            floatingLabelStyle: const TextStyle(color: Color(0xFF65D9C4)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 42),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              side: const BorderSide(color: Color(0xFF3A4B62)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF65D9C4)
                    : const Color(0xFFA8B8CB)),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF2E8F7F)
                    : const Color(0xFF344258)),
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFF65D9C4),
            thumbColor: Color(0xFF65D9C4),
            inactiveTrackColor: Color(0xFF344258),
            overlayColor: Color(0x3365D9C4),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF172438),
            selectedColor: const Color(0xFF163C3B),
            side: const BorderSide(color: Color(0xFF344258)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            labelStyle: const TextStyle(fontSize: 12),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A293B),
            contentTextStyle: const TextStyle(color: Color(0xFFE9F0F8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: TwinShell(controller: controller),
      );
}
