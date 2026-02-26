import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {

  bool includeLink = false;
  BluetoothDevice? connectedDevice;
  bool isCheckingConnection = true;
  final TextEditingController qrController = TextEditingController(text: "https://youtu.be/dQw4w9WgXcQ");

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
  Future<void> _printQR(String qrData) async {
    if (connectedDevice == null) return;

    try {
      List<BluetoothService> services = await connectedDevice!
          .discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            // Simple ESC/POS print

            final profile = await CapabilityProfile.load();
            final generator = Generator(PaperSize.mm58, profile);

            List<int> bytes = [];
            //bytes += generator.text("Device Name:");

            bytes += generator.qrcode(
              qrData,
              size: QRSize.Size8,   // 🔥 increase size
              cor: QRCorrection.H,  // high error correction
            );
            bytes += generator.cut();

            await _sendInChunks(characteristic, bytes);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===============================
    // LOADING SCREEN
    // ===============================
    if (isCheckingConnection) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        child: Column(
          children: [
            TextField(
              controller: qrController,
              onChanged: (_) {
                setState(() {});
              },
              cursorColor: Colors.black,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                labelText: "ENTER TEXT FOR QR",
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
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (qrController.text.isNotEmpty)...[
              Column(
                children: [
                  Text(
                    "QR Preview",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: 15,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),

                  QrImageView(data: qrController.text, size: 125),
                ],
              )
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (qrController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        content: Text(
                          "ENTER TEXT BEFORE PRINTING",
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

                  _printQR(qrController.text.trim());
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
                icon: const Icon(Icons.qr_code_2_outlined, color: Colors.black, size: 20,),
                label: Text(
                  "Print QR",
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

