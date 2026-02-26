import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  BluetoothDevice? connectedDevice;
  bool isCheckingConnection = true;
  final TextEditingController qrController = TextEditingController();

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

      final device = bondedDevices.firstWhere(
            (d) => d.remoteId.str == savedId,
      );

      if (!device.isConnected) {
        await device.connect(autoConnect: false);
      }

      connectedDevice = device;
    } catch (e) {
      connectedDevice = null;
    }

    setState(() => isCheckingConnection = false);
  }

  // ===============================
  // PRINT FUNCTION
  // ===============================
  Future<void> _printQR(String data) async {
    if (connectedDevice == null) return;

    try {
      List<BluetoothService> services =
      await connectedDevice!.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            // Simple ESC/POS print
            List<int> bytes = [];
            bytes += [27, 64]; // Initialize printer
            bytes += data.codeUnits;
            bytes += [10, 10, 10]; // Feed lines

            await characteristic.write(bytes, withoutResponse: true);
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No writable characteristic found")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Print failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===============================
    // LOADING SCREEN
    // ===============================
    if (isCheckingConnection) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ===============================
    // NO PRINTER CONNECTED
    // ===============================
    if (connectedDevice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("QR Print")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "No printer connected",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text("Please connect a printer first."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/connect');
                },
                child: const Text("Go to Connect Printer"),
              )
            ],
          ),
        ),
      );
    }

    // ===============================
    // QR PRINT SCREEN
    // ===============================
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Generator & Print"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                connectedDevice!.platformName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                labelText: "Enter text for QR",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            if (qrController.text.isNotEmpty)
              QrImageView(
                data: qrController.text,
                size: 200,
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (qrController.text.isEmpty) return;
                  _printQR(qrController.text);
                },
                child: const Text("Print QR Text"),
              ),
            )
          ],
        ),
      ),
    );
  }
}