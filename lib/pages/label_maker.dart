import 'dart:convert';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/db_service.dart';
import '../services/printer_service.dart';
import '../widgets/app_preferences.dart';

class LabelMaker extends StatefulWidget {
  final VoidCallback? onConnectPressed;
  const LabelMaker({super.key, this.onConnectPressed});

  @override
  State<LabelMaker> createState() => _LabelMakerState();
}

class _LabelMakerState extends State<LabelMaker> {
  bool isCheckingConnection = true;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    PrinterService.deviceNotifier.addListener(_onDeviceChange);
    _init();
  }

  @override
  void dispose() {
    PrinterService.deviceNotifier.removeListener(_onDeviceChange);
    _controller.dispose();
    super.dispose();
  }

  void _onDeviceChange() => setState(() {});

  Future<void> _init() async {
    await PrinterService.autoReconnect();
    if (mounted) setState(() => isCheckingConnection = false);
  }

  String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

  Future<void> _print() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar("ENTER TEXT BEFORE PRINTING"),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _showLoadingDialog();

    try {
      final characteristic = await PrinterService.findWritableCharacteristic();
      if (!mounted) return;
      if (characteristic == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar("NO WRITABLE CHARACTERISTIC FOUND"),
        );
        return;
      }

      final profile = await CapabilityProfile.load();
      final paperSize =
          AppPreferences.is58mm ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.feed(AppPreferences.leadingFeed.toInt());
      bytes += generator.text(
        _sanitize(text),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(AppPreferences.trailingFeed.toInt());
      bytes += generator.cut();

      await PrinterService.sendInChunks(characteristic, bytes);
      if (mounted) Navigator.of(context).pop();

      await DbService.addHistory(
        type: 'label',
        preview: text.length > 60 ? '${text.substring(0, 60)}…' : text,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(_snackBar("PRINT FAILED"));
      }
    }
  }

  Future<void> _showTemplates() async {
    final templates = await DbService.getTemplates('label');
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colors.black12),
      ),
      builder: (_) => _TemplateSheet(
        templates: templates,
        onLoad: (dataJson) {
          Navigator.pop(context);
          final data = jsonDecode(dataJson) as Map<String, dynamic>;
          _controller.text = data['text'] as String;
          setState(() {});
        },
        onDelete: (id) async => DbService.deleteTemplate(id),
        onSave: () {
          Navigator.pop(context);
          _saveTemplate();
        },
      ),
    );
  }

  Future<void> _saveTemplate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar("ENTER TEXT BEFORE SAVING TEMPLATE"),
      );
      return;
    }
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _NameDialog(controller: nameController),
    );
    if (confirmed != true || nameController.text.trim().isEmpty) return;
    await DbService.saveTemplate(
      type: 'label',
      name: nameController.text.trim(),
      dataJson: jsonEncode({'text': text}),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar("TEMPLATE SAVED"));
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PrintingDialog(),
    );
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
        title: _connectedTitle(device),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: Colors.black),
            tooltip: 'Templates',
            onPressed: _showTemplates,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              minLines: 7,
              maxLines: 7,
              keyboardType: TextInputType.multiline,
              cursorColor: Colors.black,
              style: GoogleFonts.spaceMono(fontSize: 13, color: Colors.black),
              decoration: InputDecoration(
                labelText: "ENTER TEXT FOR LABEL",
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
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_controller.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      "QR PREVIEW",
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QrImageView(
                      data: _controller.text,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "This is how the text scans as a QR code.",
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _print,
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
                ),
                icon: const Icon(Icons.label, size: 20),
                label: Text(
                  "Print Label",
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectedTitle(BluetoothDevice device) {
    return Column(
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
    );
  }

  Widget _buildConnecting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
  }

  Widget _buildNoPrinter() {
    return Center(
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
}

// ─── Reused dialogs (imported from receipt.dart via barrel) ────────────────────

class _PrintingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
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
    );
  }
}

class _NameDialog extends StatelessWidget {
  final TextEditingController controller;
  const _NameDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SAVE TEMPLATE",
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Colors.black,
              style: GoogleFonts.spaceMono(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Template name",
                hintStyle: GoogleFonts.spaceMono(
                    fontSize: 13, color: Colors.black38),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.spaceMono(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      "SAVE",
                      style: GoogleFonts.spaceMono(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
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

class _TemplateSheet extends StatefulWidget {
  final List<Map<String, dynamic>> templates;
  final void Function(String dataJson) onLoad;
  final Future<void> Function(int id) onDelete;
  final VoidCallback onSave;

  const _TemplateSheet({
    required this.templates,
    required this.onLoad,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  late List<Map<String, dynamic>> _templates;

  @override
  void initState() {
    super.initState();
    _templates = List.from(widget.templates);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TEMPLATES",
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton.icon(
                onPressed: widget.onSave,
                icon:
                    const Icon(Icons.save_alt, size: 16, color: Colors.black),
                label: Text(
                  "Save Current",
                  style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.black12),
          if (_templates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No saved templates yet.",
                  style: GoogleFonts.spaceMono(
                      fontSize: 12, color: Colors.black38),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _templates.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Colors.black12),
                itemBuilder: (_, i) {
                  final t = _templates[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.layers_outlined, size: 20),
                    title: Text(
                      t['name'] as String,
                      style: GoogleFonts.spaceMono(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.black38),
                      onPressed: () async {
                        await widget.onDelete(t['id'] as int);
                        setState(() => _templates.removeAt(i));
                      },
                    ),
                    onTap: () => widget.onLoad(t['data_json'] as String),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
