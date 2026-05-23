import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/printer_service.dart';
import 'fun_modes/badge_mode.dart';
import 'fun_modes/big_text_mode.dart';
import 'fun_modes/countdown_mode.dart';
import 'fun_modes/doodle_mode.dart';
import 'fun_modes/fortune_mode.dart';
import 'fun_modes/note_mode.dart';
import 'fun_modes/polaroid_mode.dart';
import 'fun_modes/stamps_mode.dart';

enum _Tool {
  stamps,
  fortune,
  bigText,
  polaroid,
  note,
  badge,
  doodle,
  countdown,
}

class _ToolDef {
  final _Tool id;
  final IconData icon;
  final String name;
  final String description;

  const _ToolDef(this.id, this.icon, this.name, this.description);
}

const _tools = [
  _ToolDef(_Tool.stamps, Icons.approval_outlined, 'Stamps',
      'VOID, APPROVED, TOP SECRET…'),
  _ToolDef(_Tool.fortune, Icons.auto_awesome_outlined, 'Fortune',
      'Random fortune cookie'),
  _ToolDef(
      _Tool.bigText, Icons.format_size, 'Big Text', 'Max-size bold message'),
  _ToolDef(_Tool.polaroid, Icons.photo_camera_outlined, 'Polaroid',
      'Photo with caption'),
  _ToolDef(_Tool.note, Icons.sticky_note_2_outlined, 'Sticky Note',
      'Title + body text'),
  _ToolDef(_Tool.badge, Icons.badge_outlined, 'Name Badge',
      'Name · role · event'),
  _ToolDef(
      _Tool.doodle, Icons.draw_outlined, 'Doodle', 'Draw and print anything'),
  _ToolDef(_Tool.countdown, Icons.timer_outlined, 'Countdown',
      'Days until any date'),
];

class FunMode extends StatefulWidget {
  final VoidCallback? onConnectPressed;
  const FunMode({super.key, this.onConnectPressed});

  @override
  State<FunMode> createState() => _FunModeState();
}

class _FunModeState extends State<FunMode> {
  bool _isCheckingConnection = true;
  _Tool? _activeTool;

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
    if (mounted) setState(() => _isCheckingConnection = false);
  }

  void _open(_Tool tool) => setState(() => _activeTool = tool);
  void _back() => setState(() => _activeTool = null);

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) return _buildConnecting();

    final device = PrinterService.connectedDevice;
    if (device == null) return _buildNoPrinter();

    if (_activeTool != null) return _buildTool(_activeTool!);

    return _buildHub();
  }

  Widget _buildHub() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: _tools.length,
      itemBuilder: (context, i) {
        final tool = _tools[i];
        return _ToolCard(
          def: tool,
          onTap: () => _open(tool.id),
        );
      },
    );
  }

  Widget _buildTool(_Tool tool) {
    switch (tool) {
      case _Tool.stamps:
        return StampsMode(onBack: _back);
      case _Tool.fortune:
        return FortuneMode(onBack: _back);
      case _Tool.bigText:
        return BigTextMode(onBack: _back);
      case _Tool.polaroid:
        return PolaroidMode(onBack: _back);
      case _Tool.note:
        return NoteMode(onBack: _back);
      case _Tool.badge:
        return BadgeMode(onBack: _back);
      case _Tool.doodle:
        return DoodleMode(onBack: _back);
      case _Tool.countdown:
        return CountdownMode(onBack: _back);
    }
  }

  Widget _buildConnecting() => Center(
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
                  "Connect a Bluetooth printer to use Fun Mode.",
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

class _ToolCard extends StatelessWidget {
  final _ToolDef def;
  final VoidCallback onTap;

  const _ToolCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(def.icon, size: 20, color: Colors.black),
            ),
            const Spacer(),
            Text(
              def.name,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              def.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
