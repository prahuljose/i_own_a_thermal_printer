import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

class NoteMode extends StatefulWidget {
  final VoidCallback onBack;
  const NoteMode({super.key, required this.onBack});

  @override
  State<NoteMode> createState() => _NoteModeState();
}

class _NoteModeState extends State<NoteMode> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isPrinting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Note: ${title.isNotEmpty ? title : body.substring(0, body.length.clamp(0, 30))}',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.hr(ch: '-');

        if (title.isNotEmpty) {
          bytes += g.text(
            title.toUpperCase(),
            styles: const PosStyles(bold: true, align: PosAlign.left),
          );
          bytes += g.hr(ch: '-');
        }

        if (body.isNotEmpty) {
          bytes += g.emptyLines(1);
          bytes += g.text(body, styles: const PosStyles(align: PosAlign.left));
          bytes += g.emptyLines(1);
        }

        bytes += g.hr(ch: '-');
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'STICKY NOTE', onBack: widget.onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview card (looks like a sticky note)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field (inline in the note)
                        TextField(
                          controller: _titleController,
                          maxLength: 32,
                          style: GoogleFonts.spaceMono(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Title...',
                            hintStyle: GoogleFonts.spaceMono(
                              fontSize: 15,
                              color: Colors.black26,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(
                          color: Color(0xFFFFD54F),
                          thickness: 1,
                          height: 16,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _bodyController,
                            maxLines: null,
                            expands: true,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write your note here...',
                              hintStyle: GoogleFonts.spaceMono(
                                fontSize: 13,
                                color: Colors.black26,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
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
          onPrint: hasContent ? _print : null,
        ),
      ],
    );
  }
}
