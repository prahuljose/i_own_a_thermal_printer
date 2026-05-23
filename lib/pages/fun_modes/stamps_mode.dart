import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

class StampsMode extends StatefulWidget {
  final VoidCallback onBack;
  const StampsMode({super.key, required this.onBack});

  @override
  State<StampsMode> createState() => _StampsModeState();
}

class _StampsModeState extends State<StampsMode> {
  String? _printingStamp;

  static const _stamps = [
    ('VOID',        false),
    ('APPROVED',    true),
    ('REJECTED',    false),
    ('TOP SECRET',  false),
    ('CLASSIFIED',  false),
    ('PAID',        true),
    ('FRAGILE',     false),
    ('URGENT',      false),
    ('DRAFT',       false),
    ('COPY',        false),
    ('SAMPLE',      false),
    ('ARCHIVE',     false),
  ];

  Future<void> _print(String stamp) async {
    if (_printingStamp != null) return;
    setState(() => _printingStamp = stamp);

    await runFunPrint(
      context: context,
      setLoading: (_) {},
      isMounted: () => mounted,
      historyPreview: 'Stamp: $stamp',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.hr(ch: '=');
        bytes += g.emptyLines(1);
        bytes += g.text(
          stamp,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            align: PosAlign.center,
          ),
        );
        bytes += g.emptyLines(1);
        bytes += g.hr(ch: '=');
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );

    if (mounted) setState(() => _printingStamp = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'STAMPS', onBack: widget.onBack),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _stamps.length,
            itemBuilder: (context, i) {
              final (label, positive) = _stamps[i];
              final isLoading = _printingStamp == label;
              final disabled = _printingStamp != null && !isLoading;
              return _StampButton(
                label: label,
                positive: positive,
                isLoading: isLoading,
                disabled: disabled,
                onTap: () => _print(label),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
            'Tap a stamp to print it instantly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.black38,
            ),
          ),
        ),
      ],
    );
  }
}

class _StampButton extends StatelessWidget {
  final String label;
  final bool positive;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _StampButton({
    required this.label,
    required this.positive,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLoading
        ? Colors.black
        : positive
            ? const Color(0xFFE8F5E9)
            : Colors.white;
    final border = isLoading
        ? Colors.black
        : disabled
            ? Colors.black12
            : Colors.black;
    final textColor = isLoading
        ? Colors.white
        : disabled
            ? Colors.black26
            : Colors.black;

    return GestureDetector(
      onTap: disabled || isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
