import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_own_a_thermal_printer/pages/drawer.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.yellow,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      home: DrawerPage(
      ),
    );
  }
}