import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_own_a_thermal_printer/pages/connect_printer.dart';
import 'package:i_own_a_thermal_printer/pages/home_page.dart';

enum AppView {
  home,
  connectPrinter,
  receiptBuilder,
  labelMaker,
  funMode,
  settings,
  todo,
  qr
}

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  AppView currentView = AppView.home;

  Widget _getBody() {
    switch (currentView) {
      case AppView.connectPrinter:
        return const Center(child: ConnectPrinter());
      case AppView.receiptBuilder:
        return const Center(child: Text("Receipt Builder"));
      case AppView.labelMaker:
        return const Center(child: Text("Label Maker"));
      case AppView.funMode:
        return const Center(child: HomePage());
      case AppView.home:
        return const Center(child: HomePage());
      case AppView.settings:
        return const Center(child: HomePage());
      case AppView.todo:
        return const Center(child: HomePage());
      case AppView.qr:
        return const Center(child: HomePage());
    }
  }

  String _getTitle() {
    switch (currentView) {
      case AppView.connectPrinter:
        return "Connect Printer";
      case AppView.receiptBuilder:
        return "Receipt Builder";
      case AppView.labelMaker:
        return "Label Maker";
      case AppView.funMode:
        return "Fun Mode";
      case AppView.home:
        return "I Own a Thermal Printer";
      case AppView.settings:
        return "Settings";
      case AppView.todo:
        return "To-Do";
      case AppView.qr:
        return "QR Printer";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),

        backgroundColor: Colors.black,
        title: Text(
          _getTitle(),
          style: GoogleFonts.spaceMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Thermal Printer- That's hot 🥵",
                  style: GoogleFonts.spaceMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              selected: currentView == AppView.home,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              title: Text(
                "Home",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              leading: const Icon(Icons.home),
              onTap: () {
                setState(() => currentView = AppView.home);
                Navigator.pop(context);
              },
            ),
            const Divider(),

            ListTile(
              selected: currentView == AppView.connectPrinter,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              title: Text(
                "Connect Printer",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              leading: const Icon(Icons.bluetooth),
              onTap: () {
                setState(() => currentView = AppView.connectPrinter);
                Navigator.pop(context);
              },
            ),

            ListTile(
              selected: currentView == AppView.receiptBuilder,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.receipt_long),
              title: Text(
                "Receipt Builder",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.receiptBuilder);
                Navigator.pop(context);
              },
            ),

            ListTile(
              selected: currentView == AppView.labelMaker,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.label),
              title: Text(
                "Label Maker",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.labelMaker);
                Navigator.pop(context);
              },
            ),
            ListTile(

              selected: currentView == AppView.todo,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.download_done_outlined),
              title: Text(
                "To-Do",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.todo);
                Navigator.pop(context);
              },
            ),
            ListTile(

              selected: currentView == AppView.qr,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.qr_code_rounded),
              title: Text(
                "QR Printer",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.qr);
                Navigator.pop(context);
              },
            ),
            ListTile(

              selected: currentView == AppView.funMode,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.auto_awesome),
              title: Text(
                "Fun Mode",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.funMode);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              selected: currentView == AppView.settings,
              selectedTileColor: Colors.black,
              selectedColor: Colors.white,
              leading: const Icon(Icons.settings),
              title: Text(
                "Settings",
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  //color: Colors.black,
                ),
              ),
              onTap: () {
                setState(() => currentView = AppView.settings);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _getBody(),
    );
  }
}
