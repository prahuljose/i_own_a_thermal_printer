import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:i_own_a_thermal_printer/widgets/scanning_printer_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/test_print.dart';

class ConnectPrinter extends StatefulWidget {
  // methods...
  const ConnectPrinter({super.key});

  @override
  State<ConnectPrinter> createState() => _ConnectPrinterState();
}

class _ConnectPrinterState extends State<ConnectPrinter> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    _autoReconnectPrinter();
    await _startScan();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    devices.clear();
    setState(() => isScanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          devices.add(r.device);
        }
      }
      setState(() {});
    });

    await Future.delayed(const Duration(seconds: 4));
    setState(() => isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (isConnecting) return;

    setState(() => isConnecting = true);

    try {
      // 🔁 If tapping the already connected device → disconnect
      if (connectedDevice?.remoteId == device.remoteId) {
        await device.disconnect();
        setState(() => connectedDevice = null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_printer_id');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Printer disconnected", textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // 🔌 If another device is already connected → disconnect first
        if (connectedDevice != null) {
          await connectedDevice!.disconnect();
        }

        await device.connect();
        setState(() => connectedDevice = device);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_printer_id', device.remoteId.str);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Printer connected successfully", textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => isConnecting = false);
  }

  bool isCheckingConnection = true;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: isScanning ? null : _startScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(
            isScanning ? "SCANNING..." : "SCAN FOR PRINTERS",
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // if (isScanning)
        //   const SizedBox(height: 24),
        if (isScanning) ScanningIndicator(),

        const SizedBox(height: 10),

        SizedBox(
          height: (MediaQuery.of(context).size.height)*0.65,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isConnected = connectedDevice?.remoteId == device.remoteId;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: InkWell(
                  splashColor: Colors.black.withOpacity(0.05),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _connect(device),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.device_hub_rounded,
                          size: 22,
                          color: isConnected ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 14),

                        // Device Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.platformName.isNotEmpty
                                    ? device.platformName
                                    : "UNKNOWN_DEVICE",
                                style: GoogleFonts.spaceMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: isConnected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device.remoteId.toString(),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  color: isConnected
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isConnected)
                          const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        //const SizedBox(height: 5),

        if (connectedDevice != null) ...[
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: isConnecting
                ? null
                : () async {
              if (connectedDevice != null) {
                await testPrint(connectedDevice!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.print),
            label: Text(
              "TEST PRINT",
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
