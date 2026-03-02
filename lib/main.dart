import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_own_a_thermal_printer/pages/drawer.dart';
import 'package:i_own_a_thermal_printer/widgets/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.yellow,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await AppPreferences.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,

        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: GoogleFonts.spaceMono(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 1),
          ),

          elevation: 0,
        ),
      ),

      home: const DrawerPage(),
    );
  }
}
