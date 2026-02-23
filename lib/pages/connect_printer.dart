import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:i_own_a_thermal_printer/widgets/scanning_printer_animation.dart';

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
    setState(() => isConnecting = true);

    try {
      await device.connect();
      connectedDevice = device;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Connected successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }

    setState(() => isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: isScanning ? null : _startScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
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

        if (isScanning)
          ScanningIndicator(),

        const SizedBox(height: 10),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isConnected =
                  connectedDevice?.remoteId == device.remoteId;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
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
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ),
      ],
    );
  }
}

