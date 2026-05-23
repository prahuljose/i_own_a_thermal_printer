import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/db_service.dart';
import '../services/image_utils.dart';
import '../services/printer_service.dart';
import '../widgets/app_preferences.dart';

class FunMode extends StatefulWidget {
  final VoidCallback? onConnectPressed;
  const FunMode({super.key, this.onConnectPressed});

  @override
  State<FunMode> createState() => _FunModeState();
}

class _FunModeState extends State<FunMode> {
  Uint8List? _imageBytes;
  bool isCheckingConnection = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    PrinterService.deviceNotifier.addListener(_onDeviceChange);
    _init();
  }

  @override
  void dispose() {
    PrinterService.deviceNotifier.removeListener(_onDeviceChange);
    super.dispose();
  }

  void _onDeviceChange() => setState(() {});

  Future<void> _init() async {
    await PrinterService.autoReconnect();
    if (mounted) setState(() => isCheckingConnection = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  void _removeImage() => setState(() => _imageBytes = null);

  Future<void> _print() async {
    if (_imageBytes == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isPrinting = true);

    try {
      final characteristic = await PrinterService.findWritableCharacteristic();
      if (!mounted) return;
      if (characteristic == null) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar("NO WRITABLE CHARACTERISTIC FOUND"),
        );
        return;
      }

      // 384 dots for 58mm, 576 for 80mm (byte-aligned, exact printer DPI)
      final targetWidth = AppPreferences.is58mm ? 384 : 576;

      // Heavy processing (decode → orient → resize → grayscale → F-S dither)
      // runs in a background isolate so the UI stays responsive.
      final prepared = await prepareImageForPrint(
        _imageBytes!,
        targetWidth,
        maxHeight: 800,
      );
      if (!mounted) return;
      if (prepared == null) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(_snackBar("IMAGE ERROR"));
        return;
      }

      final profile = await CapabilityProfile.load();
      if (!mounted) return;

      final paperSize =
          AppPreferences.is58mm ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.feed(AppPreferences.leadingFeed.toInt());
      // imageRaster (GS v 0) sends the full bitmap in one block — the printer
      // buffers it and prints continuously with no strip-by-strip pauses.
      bytes += generator.imageRaster(prepared);
      bytes += generator.feed(AppPreferences.trailingFeed.toInt());
      bytes += generator.cut();

      await PrinterService.sendInChunks(characteristic, bytes);

      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(_snackBar("PRINTED!"));
      }

      await DbService.addHistory(
        type: 'label',
        preview: 'Fun Mode image print',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(_snackBar("PRINT FAILED"));
      }
    }
  }

  SnackBar _snackBar(String text) => SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
      );

  @override
  Widget build(BuildContext context) {
    if (isCheckingConnection) return _buildConnecting();

    final device = PrinterService.connectedDevice;
    if (device == null) return _buildNoPrinter();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              device.platformName.toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.black,
              ),
            ),
            Text(
              "CONNECTED",
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                letterSpacing: 1.2,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview area
            Expanded(
              child: _imageBytes != null
                  ? _buildPreview()
                  : _buildPickerPlaceholder(),
            ),

            const SizedBox(height: 16),

            // Pick buttons row
            if (_imageBytes == null) ...[
              Row(
                children: [
                  Expanded(
                    child: _pickButton(
                      icon: Icons.photo_library_outlined,
                      label: "Gallery",
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickButton(
                      icon: Icons.camera_alt_outlined,
                      label: "Camera",
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _removeImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        "Remove",
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(
                        "Change",
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPrinting ? null : _print,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.black38,
                  ),
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.print_rounded, size: 20),
                  label: Text(
                    _isPrinting ? "PRINTING..." : "Print Image",
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                ),
                // Grayscale overlay hint
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Prints in grayscale · ${AppPreferences.is58mm ? '58mm' : '80mm'} width",
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: Border.all(color: Colors.black12, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 56,
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            "Select an image to print",
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              color: Colors.black38,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Full paper width · Grayscale dithered",
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  "Connecting to saved printer...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildNoPrinter() => Center(
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
                const Icon(Icons.print_disabled_outlined,
                    size: 48, color: Colors.black38),
                const SizedBox(height: 20),
                Text(
                  "NO PRINTER CONNECTED",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Connect a Bluetooth printer to start printing.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onConnectPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bluetooth_searching, size: 18),
                    label: Text(
                      "Go to Connect Printer",
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
