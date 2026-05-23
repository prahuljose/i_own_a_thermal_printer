import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/printer_service.dart';
import '../widgets/app_preferences.dart';
import '../widgets/test_print.dart';

class ConnectPrinter extends StatefulWidget {
  const ConnectPrinter({super.key});

  @override
  State<ConnectPrinter> createState() => _ConnectPrinterState();
}

class _ConnectPrinterState extends State<ConnectPrinter> {
  // Keyed by remoteId so we overwrite stale results with fresher RSSI.
  final Map<String, ScanResult> _results = {};
  bool _isScanning = false;
  String? _connectingId; // remoteId of the device currently being connected
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await AppPreferences.init();
    await _requestPermissions();
    await PrinterService.autoReconnect();
    if (mounted) setState(() {});
    _startScan();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    _results.clear();
    _scanSub?.cancel();
    setState(() => _isScanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          _results[r.device.remoteId.str] = r;
        }
      });
    });

    await Future.delayed(const Duration(seconds: 6));
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_connectingId != null) return;
    setState(() => _connectingId = device.remoteId.str);

    try {
      final current = PrinterService.connectedDevice;

      if (current?.remoteId == device.remoteId) {
        await device.disconnect();
        PrinterService.setDevice(null);
        await PrinterService.persistDeviceId(null);
        _showSnack("Printer disconnected");
      } else {
        if (current != null) await current.disconnect();
        await device.connect();
        PrinterService.setDevice(device);
        await PrinterService.requestMtu();
        await PrinterService.persistDeviceId(device.remoteId.str);
        _showSnack("Connected to ${device.platformName.isNotEmpty ? device.platformName : 'printer'}");
      }
    } catch (e) {
      _showSnack("Connection failed: $e");
    }

    if (mounted) setState(() => _connectingId = null);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: PrinterService.deviceNotifier,
      builder: (context, connectedDevice, child) {
        // Devices visible in scan, excluding the one already connected
        final otherDevices = _results.values
            .where((r) => r.device.remoteId != connectedDevice?.remoteId)
            .toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ── Connected device card ─────────────────────────────────────
            if (connectedDevice != null)
              _ConnectedCard(
                device: connectedDevice,
                isConnecting: _connectingId != null,
                onDisconnect: () => _connect(connectedDevice),
                onTestPrint: () => testPrint(connectedDevice),
              ),

            if (connectedDevice != null) const SizedBox(height: 20),

            // ── Scan row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ScanButton(
                isScanning: _isScanning,
                onTap: _isScanning ? _stopScan : _startScan,
              ),
            ),

            const SizedBox(height: 8),

            // ── Device list ───────────────────────────────────────────────
            Expanded(
              child: otherDevices.isEmpty
                  ? _EmptyState(isScanning: _isScanning)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: otherDevices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final result = otherDevices[index];
                        return _DeviceTile(
                          result: result,
                          connectingId: _connectingId,
                          onTap: () => _connect(result.device),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Connected device card ──────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  final BluetoothDevice device;
  final bool isConnecting;
  final VoidCallback onDisconnect;
  final VoidCallback onTestPrint;

  const _ConnectedCard({
    required this.device,
    required this.isConnecting,
    required this.onDisconnect,
    required this.onTestPrint,
  });

  @override
  Widget build(BuildContext context) {
    final name = device.platformName.isNotEmpty
        ? device.platformName.toUpperCase()
        : 'UNKNOWN PRINTER';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "CONNECTED",
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              device.remoteId.str,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: "TEST PRINT",
                    icon: Icons.print_outlined,
                    onTap: isConnecting ? null : onTestPrint,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardButton(
                    label: "DISCONNECT",
                    icon: Icons.bluetooth_disabled_outlined,
                    onTap: isConnecting ? null : onDisconnect,
                    filled: true,
                    destructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool destructive;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF6B6B) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null ? Colors.white12 : color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: onTap == null ? Colors.white24 : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: onTap == null ? Colors.white24 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan button ───────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onTap;

  const _ScanButton({required this.isScanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isScanning ? const Color(0xFFF0F0F0) : Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              ),
            ] else
              const Icon(Icons.bluetooth_searching,
                  size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              isScanning ? "SCANNING...  TAP TO STOP" : "SCAN FOR PRINTERS",
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isScanning ? Colors.black54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Device tile ───────────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  final ScanResult result;
  final String? connectingId;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.result,
    required this.connectingId,
    required this.onTap,
  });

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return const Color(0xFF4ADE80);
    if (rssi >= -75) return const Color(0xFFFBBF24);
    return const Color(0xFFFF6B6B);
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -60) return "STRONG";
    if (rssi >= -75) return "FAIR";
    return "WEAK";
  }

  @override
  Widget build(BuildContext context) {
    final device = result.device;
    final thisId = device.remoteId.str;
    final isThisConnecting = connectingId == thisId;
    final anyConnecting = connectingId != null;

    final name = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    final rssiColor = _rssiColor(result.rssi);

    return GestureDetector(
      onTap: anyConnecting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isThisConnecting ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isThisConnecting ? Colors.black : Colors.black12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Signal dot — becomes spinner while connecting
            SizedBox(
              width: 14,
              height: 14,
              child: isThisConnecting
                  ? CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white54),
                    )
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: anyConnecting ? Colors.black26 : rssiColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isThisConnecting
                          ? Colors.white
                          : anyConnecting
                              ? Colors.black38
                              : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isThisConnecting ? "Connecting..." : device.remoteId.str,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: isThisConnecting
                          ? Colors.white38
                          : Colors.black38,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Signal info — hidden while connecting
            if (!isThisConnecting) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _rssiLabel(result.rssi),
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: anyConnecting ? Colors.black26 : rssiColor,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "${result.rssi} dBm",
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: anyConnecting ? Colors.black12 : Colors.black26,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isScanning;

  const _EmptyState({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              "Looking for printers nearby...",
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled_outlined,
                size: 40, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              "No printers found",
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Make sure your printer is powered on and Bluetooth is enabled, then scan again.",
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.black38,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
