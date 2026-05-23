import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

class BigTextMode extends StatefulWidget {
  final VoidCallback onBack;
  const BigTextMode({super.key, required this.onBack});

  @override
  State<BigTextMode> createState() => _BigTextModeState();
}

class _BigTextModeState extends State<BigTextMode> {
  final _controller = TextEditingController();
  bool _isPrinting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Big Text: $text',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.hr(ch: '-');
        bytes += g.emptyLines(1);
        bytes += g.text(
          text.toUpperCase(),
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            align: PosAlign.center,
          ),
        );
        bytes += g.emptyLines(1);
        bytes += g.hr(ch: '-');
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'BIG TEXT', onBack: widget.onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: funInputDecoration(
                    'Your message',
                    hint: 'HELLO WORLD',
                  ).copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Preview card
                if (text.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '- - - - - - - - - - - -',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceMono(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '- - - - - - - - - - - -',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Type something above\nto see a preview',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color: Colors.black26,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        FunPrintButton(
          isPrinting: _isPrinting,
          onPrint: _controller.text.trim().isEmpty ? null : _print,
        ),
      ],
    );
  }
}
