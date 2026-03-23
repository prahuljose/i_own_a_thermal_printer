import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../widgets/app_preferences.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  List<String> todoItems = ["Apples", "Oranges", "Asteroid Destroyer", "10,000 cans of sugar-free, diet, caffeine free, seven up flavored soda"];
  IconData selectedIcon = Icons.check_box_outlined;

  Widget _iconOption(IconData icon) {
    final isSelected = selectedIcon == icon;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIcon = icon;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black,
          size: 18,
        ),
      ),
    );
  }

  bool includeLink = false;
  BluetoothDevice? connectedDevice;
  bool isCheckingConnection = true;
  final TextEditingController qrController = TextEditingController(
    text:
        "Item 5"
  );

  @override
  void initState() {
    super.initState();
    _autoReconnectPrinter();
  }

  // ===============================
  // AUTO RECONNECT SAVED PRINTER
  // ===============================
  Future<void> _autoReconnectPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_printer_id');

    if (savedId == null) {
      setState(() => isCheckingConnection = false);
      return;
    }

    try {
      final bondedDevices = await FlutterBluePlus.bondedDevices;

      final device = bondedDevices.firstWhere((d) => d.remoteId.str == savedId);

      if (!device.isConnected) {
        await device.connect(autoConnect: false);
      }

      connectedDevice = device;
    } catch (e) {
      connectedDevice = null;
    }

    setState(() => isCheckingConnection = false);
  }

  Future<void> _sendInChunks(
    BluetoothCharacteristic characteristic,
    List<int> data,
  ) async {
    const chunkSize = 20;

    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;

      await characteristic.write(data.sublist(i, end), withoutResponse: true);

      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // ===============================
  // PRINT FUNCTION
  // ===============================
  Future<void> _printLabel(String qrText) async {
    if (connectedDevice == null) return;

    try {
      List<BluetoothService> services = await connectedDevice!
          .discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            // Simple ESC/POS print

            final profile = await CapabilityProfile.load();
            final paperSize = AppPreferences.is58mm
                ? PaperSize.mm58
                : PaperSize.mm80;

            final generator = Generator(paperSize, profile);

            List<int> bytes = [];
            bytes += generator.reset();
            //bytes += generator.text("Device Name:");

            bytes += generator.feed(AppPreferences.leadingFeed.toInt());

            // bytes += generator.qrcode(
            //   qrData,
            //   size: QRSize.Size8, // 🔥 increase size
            //   cor: QRCorrection.H, // high error correction
            // );

            // if (includeLink) {
            //   bytes += generator.feed(2);
            //   bytes += generator.text(
            //     qrText,
            //     styles: const PosStyles(
            //       align: PosAlign.center,
            //       //bold: true,
            //       //height: PosTextSize.size2,
            //       //width: PosTextSize.size2,
            //     ),
            //   );
            // }


            bytes += generator.text(
                  "My List:",
                  styles: const PosStyles(
                    align: PosAlign.center,
                    bold: true,
                    height: PosTextSize.size2,
                    width: PosTextSize.size2,
                  ),
            );

            bytes += generator.feed(1);

            for (var item in todoItems) {
              bytes += generator.text(
                "[  ] $item",
                styles: const PosStyles(align: PosAlign.left),
              );
              bytes += generator.feed(1);
            }

            bytes += generator.feed(AppPreferences.trailingFeed.toInt());

            bytes += generator.cut();

            _showLoadingDialog();
            await _sendInChunks(characteristic, bytes);
            Navigator.of(context).pop(); // close dialog

            //await characteristic.write(bytes, withoutResponse: true);
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No writable characteristic found")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Print failed")));
      print(e);
    }
  }

  String sanitizeText(String input) {
    return input.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // prevents closing manually
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "PRINTING...",
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===============================
    // LOADING SCREEN
    // ===============================
    if (isCheckingConnection) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 25),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Attempting to connect to previously saved printer.",
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ===============================
    // NO PRINTER CONNECTED
    // ===============================
    if (connectedDevice == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.print_outlined,
                    size: 48,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "NO PRINTER CONNECTED",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "SpaceMono",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Navigate to the Connect Printer section, and connect a printer to continue!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    // ===============================
    // QR PRINT SCREEN
    // ===============================
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              connectedDevice!.platformName.toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.black,
              ),
            ),
            Text(
              "CONNECTED",
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        // bottom: const PreferredSize(
        //   preferredSize: Size.fromHeight(1),
        //   child: Divider(
        //     height: 1,
        //     thickness: 1,
        //     color: Colors.black,
        //   ),
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qrController,
                    decoration: InputDecoration(
                      hintText: "Add item",

                        labelText: "Item List",
                        labelStyle: GoogleFonts.spaceMono(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: Colors.black54,
                        ),
                        floatingLabelStyle: GoogleFonts.spaceMono(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: Colors.black,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        )
                    ),

                    minLines: 1,
                    maxLines: 3,
                    // 👈 allows expansion
                    keyboardType: TextInputType.multiline,
                    cursorColor: Colors.black,
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (qrController.text.trim().isEmpty) return;

                    setState(() {
                      todoItems.add(qrController.text.trim());
                      qrController.clear();
                    });
                  },
                ),
              ],
            ),


            const SizedBox(height: 20),



            Column(
              children: todoItems.asMap().entries.map((entry) {
                int index = entry.key;
                String item = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "[ ]",
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          letterSpacing: 0.8,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            todoItems.removeAt(index);
                          });
                        },
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            //generating the QR on UI
            // if (qrController.text.isNotEmpty) ...[
            //   Column(
            //     children: [
            //       Text(
            //         "QR Preview",
            //         textAlign: TextAlign.center,
            //         style: GoogleFonts.spaceMono(
            //           fontSize: 15,
            //           letterSpacing: 1.2,
            //           color: Colors.black,
            //         ),
            //       ),
            //
            //       QrImageView(data: qrController.text, size: 200),
            //       if (includeLink) ...[
            //         Text(
            //           qrController.text,
            //           textAlign: TextAlign.center,
            //           style: GoogleFonts.spaceMono(
            //             fontSize: 15,
            //             letterSpacing: 1.2,
            //             color: Colors.black87,
            //           ),
            //         ),
            //       ],
            //     ],
            //   ),
            // ],
            const Spacer(),
            const SizedBox(height: 30),

            // GestureDetector(
            //   onTap: () {
            //     setState(() {
            //       includeLink = !includeLink;
            //     });
            //   },
            //   child: AnimatedContainer(
            //     duration: const Duration(milliseconds: 150),
            //     padding: const EdgeInsets.symmetric(vertical: 18),
            //     decoration: BoxDecoration(
            //       color: includeLink ? Colors.black : Colors.white,
            //       borderRadius: BorderRadius.circular(4),
            //       border: Border.all(color: Colors.black, width: 1.5),
            //     ),
            //     child: Center(
            //       child: Text(
            //         includeLink ? "TEXT INCLUDED" : "INCLUDE TEXT",
            //         style: GoogleFonts.spaceMono(
            //           fontSize: 12,
            //           fontWeight: FontWeight.bold,
            //           letterSpacing: 0.8,
            //           color: includeLink ? Colors.white : Colors.black,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            //SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (todoItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        content: Text(
                          "ADD ITEMS INTO LIST BEFORE PRINTING",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }

                  _printLabel(qrController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.white,
                  disabledForegroundColor: Colors.black38,
                ),
                icon: const Icon(Icons.list_alt, color: Colors.black, size: 20),
                label: Text(
                  "Print To-Do List",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
