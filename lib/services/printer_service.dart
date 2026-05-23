import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  PrinterService._();

  static final ValueNotifier<BluetoothDevice?> deviceNotifier =
      ValueNotifier(null);

  // BLE ATT default is 23 bytes (20 bytes payload). After MTU negotiation
  // this gets bumped to whatever the printer supports (often 128–512).
  static int _negotiatedMtu = 23;

  static BluetoothDevice? get connectedDevice => deviceNotifier.value;

  /// Negotiate a higher MTU with the connected device.
  /// Call once right after a successful device.connect().
  static Future<void> requestMtu() async {
    final device = connectedDevice;
    if (device == null) return;
    try {
      _negotiatedMtu = await device.requestMtu(512);
      if (kDebugMode) print('BLE MTU negotiated: $_negotiatedMtu bytes');
    } catch (e) {
      _negotiatedMtu = 23;
      if (kDebugMode) print('MTU negotiation failed, using default: $e');
    }
  }

  static Future<bool> autoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_printer_id');

    if (savedId == null) return false;

    try {
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      final device = bondedDevices.firstWhere(
        (d) => d.remoteId.str == savedId,
      );

      if (!device.isConnected) {
        await device.connect(autoConnect: false);
        await requestMtu();
      }

      deviceNotifier.value = device;
      return true;
    } catch (_) {
      deviceNotifier.value = null;
      return false;
    }
  }

  static void setDevice(BluetoothDevice? device) {
    deviceNotifier.value = device;
    if (device == null) _negotiatedMtu = 23;
  }

  static Future<void> persistDeviceId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('saved_printer_id');
    } else {
      await prefs.setString('saved_printer_id', id);
    }
  }

  static Future<BluetoothCharacteristic?> findWritableCharacteristic() async {
    final device = connectedDevice;
    if (device == null) return null;

    try {
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write) return characteristic;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Characteristic discovery failed: $e');
    }
    return null;
  }

  static Future<void> sendInChunks(
    BluetoothCharacteristic characteristic,
    List<int> data,
  ) async {
    // Use negotiated MTU minus 3 bytes ATT overhead.
    // Falls back to 20 bytes if MTU was never negotiated.
    final chunkSize = _negotiatedMtu > 23 ? _negotiatedMtu - 3 : 20;

    // 10ms is safe for most thermal printers. The big win comes from larger
    // chunks after MTU negotiation: a 200-byte MTU + 10ms ≈ 50× faster than
    // 20-byte + 50ms.
    const delayMs = 10;

    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
      await characteristic.write(
        data.sublist(i, end),
        withoutResponse: true,
      );
      await Future.delayed(const Duration(milliseconds: delayMs));
    }
  }
}
