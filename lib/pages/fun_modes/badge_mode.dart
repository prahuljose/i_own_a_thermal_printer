import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

class BadgeMode extends StatefulWidget {
  final VoidCallback onBack;
  const BadgeMode({super.key, required this.onBack});

  @override
  State<BadgeMode> createState() => _BadgeModeState();
}

class _BadgeModeState extends State<BadgeMode> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _eventController = TextEditingController();
  bool _isPrinting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final role = _roleController.text.trim();
    final event = _eventController.text.trim();

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Badge: $name',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.hr(ch: '=');
        bytes += g.emptyLines(1);

        bytes += g.text(
          name.toUpperCase(),
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            align: PosAlign.center,
          ),
        );

        bytes += g.emptyLines(1);

        if (role.isNotEmpty) {
          bytes += g.text(
            role,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
            ),
          );
        }

        if (event.isNotEmpty) {
          bytes += g.text(
            event,
            styles: const PosStyles(align: PosAlign.center),
          );
        }

        bytes += g.emptyLines(1);
        bytes += g.hr(ch: '=');
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final event = _eventController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'NAME BADGE', onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: funInputDecoration('Name *', hint: 'Alex Chen')
                      .copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roleController,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.spaceMono(fontSize: 14),
                  decoration: funInputDecoration('Role / Title',
                          hint: 'Lead Designer')
                      .copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventController,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.spaceMono(fontSize: 14),
                  decoration: funInputDecoration('Event / Company',
                          hint: 'Acme Conf 2025')
                      .copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Preview
                if (name.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            role,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        if (event.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                        Container(
                          height: 3,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        FunPrintButton(
          isPrinting: _isPrinting,
          onPrint: name.isEmpty ? null : _print,
        ),
      ],
    );
  }
}
