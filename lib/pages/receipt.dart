import 'dart:convert';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/db_service.dart';
import '../services/image_utils.dart';
import '../services/printer_service.dart';
import '../widgets/app_preferences.dart';

class Receipt extends StatefulWidget {
  final VoidCallback? onConnectPressed;
  const Receipt({super.key, this.onConnectPressed});

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  List<String> todoItems = [];
  List<String> todoItemsQuantity = [];
  List<String> todoItemsPrice = [];
  double totalPrice = 0;

  int _selectedQty = 1;
  Uint8List? _headerImageBytes;

  bool isCheckingConnection = true;

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    PrinterService.deviceNotifier.addListener(_onDeviceChange);
    _init();
  }

  @override
  void dispose() {
    PrinterService.deviceNotifier.removeListener(_onDeviceChange);
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onDeviceChange() => setState(() {});

  Future<void> _init() async {
    await PrinterService.autoReconnect();
    if (mounted) setState(() => isCheckingConnection = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Limit source resolution before even loading into memory.
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _headerImageBytes = bytes);
  }

  void _removeImage() => setState(() => _headerImageBytes = null);

  void _addItem() {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      todoItems.add(name);
      todoItemsQuantity.add(_selectedQty.toString());
      todoItemsPrice.add(price.toStringAsFixed(2));
      totalPrice += price * _selectedQty;
      _itemController.clear();
      _priceController.clear();
      _selectedQty = 1;
    });
  }

  void _removeItem(int index) {
    setState(() {
      totalPrice -= double.parse(todoItemsPrice[index]) *
          double.parse(todoItemsQuantity[index]);
      todoItems.removeAt(index);
      todoItemsPrice.removeAt(index);
      todoItemsQuantity.removeAt(index);
    });
  }

  Future<void> _print() async {
    if (todoItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar("ADD ITEMS BEFORE PRINTING"),
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

      if (_headerImageBytes != null) {
        // 384/576 = exact printer dots for 58/80mm. Height cap at 150px keeps
        // receipt headers compact and fast to transfer.
        final targetWidth = AppPreferences.is58mm ? 384 : 576;
        final prepared = await prepareImageForPrint(
          _headerImageBytes!,
          targetWidth,
          maxHeight: 150,
        );
        if (!mounted) return;
        if (prepared != null) {
          bytes += generator.imageRaster(prepared);
          bytes += generator.feed(1);
        }
      }

      bytes += generator.text(
        "Receipt:",
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
      bytes += generator.hr();

      for (int i = 0; i < todoItems.length; i++) {
        bytes += generator.row([
          PosColumn(text: todoItemsQuantity[i], width: 1),
          PosColumn(text: " x", width: 1),
          PosColumn(text: " ${todoItems[i]}", width: 6),
          PosColumn(
            text: todoItemsPrice[i],
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: totalPrice.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr();
      bytes += generator.feed(AppPreferences.trailingFeed.toInt());
      bytes += generator.cut();

      await PrinterService.sendInChunks(characteristic, bytes);
      if (mounted) Navigator.of(context).pop();

      await DbService.addHistory(
        type: 'receipt',
        preview: '${todoItems.length} item(s) · Total ${totalPrice.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(_snackBar("PRINT FAILED"));
      }
    }
  }

  Future<void> _showTemplates() async {
    final templates = await DbService.getTemplates('receipt');
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
          _loadTemplate(dataJson);
        },
        onDelete: (id) async {
          await DbService.deleteTemplate(id);
        },
        onSave: () {
          Navigator.pop(context);
          _saveTemplate();
        },
      ),
    );
  }

  void _loadTemplate(String dataJson) {
    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    final items = List<String>.from(data['items'] as List);
    final quantities = List<String>.from(data['quantities'] as List);
    final prices = List<String>.from(data['prices'] as List);
    double total = 0;
    for (int i = 0; i < prices.length; i++) {
      total += double.parse(prices[i]) * double.parse(quantities[i]);
    }
    setState(() {
      todoItems = items;
      todoItemsQuantity = quantities;
      todoItemsPrice = prices;
      totalPrice = total;
    });
  }

  Future<void> _saveTemplate() async {
    if (todoItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar("ADD ITEMS BEFORE SAVING TEMPLATE"),
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
      type: 'receipt',
      name: nameController.text.trim(),
      dataJson: jsonEncode({
        'items': todoItems,
        'quantities': todoItemsQuantity,
        'prices': todoItemsPrice,
      }),
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

  Widget _buildNumberPicker() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.light,
          textTheme: CupertinoTextThemeData(
            pickerTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: 0),
          itemExtent: 30,
          backgroundColor: Colors.white,
          selectionOverlay: Container(
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
          onSelectedItemChanged: (index) {
            setState(() => _selectedQty = index + 1);
          },
          children: List.generate(
            50,
            (i) => Center(
              child: Text(
                '${i + 1}',
                style: GoogleFonts.spaceMono(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: Colors.black,
      style: GoogleFonts.spaceMono(fontSize: 13, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceMono(
          fontSize: 12,
          color: Colors.black54,
          letterSpacing: 0.8,
        ),
        floatingLabelStyle: GoogleFonts.spaceMono(
          fontSize: 12,
          color: Colors.black,
          letterSpacing: 0.8,
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
    );
  }

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
            // Header image section
            _buildImageSection(),
            const SizedBox(height: 16),

            // Add item row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 44, child: _buildNumberPicker()),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: _buildTextField(_itemController, "Item"),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    _priceController,
                    "Price",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addItem,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Items list
            if (todoItems.isNotEmpty) ...[
              ...todoItems.asMap().entries.map((entry) {
                final i = entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${todoItemsQuantity[i]} x",
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todoItems[i],
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        todoItemsPrice[i],
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeItem(i),
                        child: const Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Colors.black12, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TOTAL",
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    totalPrice.toStringAsFixed(2),
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
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
                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                label: Text(
                  "Print Receipt",
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_headerImageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _headerImageBytes!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "HEADER IMAGE",
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black26,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 20, color: Colors.black38),
            const SizedBox(width: 8),
            Text(
              "ADD HEADER IMAGE (OPTIONAL)",
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: Colors.black38,
                letterSpacing: 0.8,
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
                  color: Colors.black,
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
                  color: Colors.black,
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

// ─── Shared dialogs ────────────────────────────────────────────────────────────

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
                  fontSize: 13,
                  color: Colors.black38,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                icon: const Icon(Icons.save_alt, size: 16, color: Colors.black),
                label: Text(
                  "Save Current",
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
                    fontSize: 12,
                    color: Colors.black38,
                  ),
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
                    leading: const Icon(Icons.layers_outlined, size: 20),
                    title: Text(
                      t['name'] as String,
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
