import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<void> testPrint(BluetoothDevice device) async {
  // 1️⃣ Discover services
  List<BluetoothService> services = await device.discoverServices();

  BluetoothCharacteristic? writeChar;

  for (var service in services) {
    for (var characteristic in service.characteristics) {
      if (characteristic.properties.write ||
          characteristic.properties.writeWithoutResponse) {
        writeChar = characteristic;
        break;
      }
    }
  }

  if (writeChar == null) {
    print("No writable characteristic found");
    return;
  }

  // 2️⃣ Generate receipt
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm58, profile);

  List<int> bytes = [];

  bytes += generator.reset();

  bytes += generator.text(
    'POLITE WEATHER POS',
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  );

  bytes += generator.hr();

  bytes += generator.text(
    'Bluetooth Printer Test',
    styles: const PosStyles(align: PosAlign.center),
  );

  bytes += generator.feed(1);

  bytes += generator.row([
    PosColumn(text: '1 x Sample Item', width: 8),
    PosColumn(
      text: '100.00',
      width: 4,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: '2 x Demo Product', width: 8),
    PosColumn(
      text: '250.00',
      width: 4,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.hr();

  bytes += generator.row([
    PosColumn(
      text: 'TOTAL',
      width: 6,
      styles: const PosStyles(bold: true),
    ),
    PosColumn(
      text: '350.00',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.right,
        bold: true,
      ),
    ),
  ]);

  bytes += generator.feed(1);

  bytes += generator.text('abcdefghijklmnopqrstuvwxyz');
  bytes += generator.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  bytes += generator.text('1234567890');

  bytes += generator.feed(2);
  bytes += generator.cut();

  // 3️⃣ Send in chunks (VERY important for BLE)
  await _sendInChunks(writeChar, bytes);
}

Future<void> _sendInChunks(
    BluetoothCharacteristic characteristic,
    List<int> data,
    ) async {
  const chunkSize = 20;

  for (int i = 0; i < data.length; i += chunkSize) {
    final end =
    (i + chunkSize > data.length) ? data.length : i + chunkSize;

    await characteristic.write(
      data.sublist(i, end),
      withoutResponse: true,
    );

    await Future.delayed(const Duration(milliseconds: 50));
  }
}