import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_own_a_thermal_printer/pages/connect_printer.dart';
import 'package:i_own_a_thermal_printer/pages/history_page.dart';
import 'package:i_own_a_thermal_printer/pages/home_page.dart';
import 'package:i_own_a_thermal_printer/pages/qr.dart';
import 'package:i_own_a_thermal_printer/pages/receipt.dart';
import 'package:i_own_a_thermal_printer/pages/settings_page.dart';
import 'package:i_own_a_thermal_printer/pages/todo.dart';
import 'package:i_own_a_thermal_printer/services/printer_service.dart';

import 'fun_mode.dart';
import 'label_maker.dart';

enum AppView {
  home,
  connectPrinter,
  receiptBuilder,
  labelMaker,
  funMode,
  settings,
  todo,
  qr,
  history,
  love,
}

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  AppView currentView = AppView.home;

  void _navigateTo(AppView view) {
    setState(() => currentView = view);
  }

  Widget _getBody() {
    void goToConnect() {
      _navigateTo(AppView.connectPrinter);
    }

    switch (currentView) {
      case AppView.connectPrinter:
        return ConnectPrinter();
      case AppView.receiptBuilder:
        return Receipt(onConnectPressed: goToConnect);
      case AppView.labelMaker:
        return LabelMaker(onConnectPressed: goToConnect);
      case AppView.funMode:
        return FunMode(onConnectPressed: goToConnect);
      case AppView.home:
        return const HomePage();
      case AppView.settings:
        return const SettingsPage();
      case AppView.todo:
        return Todo(onConnectPressed: goToConnect);
      case AppView.qr:
        return QrPage(onConnectPressed: goToConnect);
      case AppView.history:
        return const HistoryPage();
      case AppView.love:
        return const Center(child: Text("Show some love <3"));
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
      case AppView.history:
        return "Print History";
      case AppView.love:
        return "Awww <3";
    }
  }

  Widget _drawerTile({
    required AppView view,
    required String label,
    required IconData icon,
    Widget? trailing,
  }) {
    final selected = currentView == view;
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.black,
      selectedColor: Colors.white,
      leading: Icon(icon),
      title: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: trailing,
      onTap: () {
        setState(() => currentView = view);
        Navigator.pop(context);
      },
    );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Thermal Printer",
                    style: GoogleFonts.spaceMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<dynamic>(
                    valueListenable: PrinterService.deviceNotifier,
                    builder: (context, device, child) {
                      final isConnected = device != null;
                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? const Color(0xFF00E676)
                                  : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected
                                ? device.platformName.isNotEmpty
                                    ? device.platformName
                                    : "Connected"
                                : "No printer connected",
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: isConnected
                                  ? Colors.white70
                                  : Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            _drawerTile(
              view: AppView.home,
              label: "Home",
              icon: Icons.home,
            ),
            const Divider(),
            ValueListenableBuilder<dynamic>(
              valueListenable: PrinterService.deviceNotifier,
              builder: (context, device, child) {
                return _drawerTile(
                  view: AppView.connectPrinter,
                  label: "Connect Printer",
                  icon: Icons.bluetooth,
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: device != null
                          ? const Color(0xFF00E676)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: device != null
                          ? null
                          : Border.all(color: Colors.black26, width: 1),
                    ),
                  ),
                );
              },
            ),
            _drawerTile(
              view: AppView.receiptBuilder,
              label: "Receipt Builder",
              icon: Icons.receipt_long,
            ),
            _drawerTile(
              view: AppView.labelMaker,
              label: "Label Maker",
              icon: Icons.label,
            ),
            _drawerTile(
              view: AppView.todo,
              label: "To-Do",
              icon: Icons.checklist,
            ),
            _drawerTile(
              view: AppView.qr,
              label: "QR Printer",
              icon: Icons.qr_code_rounded,
            ),
            _drawerTile(
              view: AppView.funMode,
              label: "Fun Mode",
              icon: Icons.auto_awesome,
            ),
            const Divider(),
            _drawerTile(
              view: AppView.history,
              label: "Print History",
              icon: Icons.history,
            ),
            _drawerTile(
              view: AppView.settings,
              label: "Settings",
              icon: Icons.settings,
            ),
            _drawerTile(
              view: AppView.love,
              label: "Show some 🖤",
              icon: Icons.rate_review,
            ),
          ],
        ),
      ),
      body: _getBody(),
    );
  }
}
