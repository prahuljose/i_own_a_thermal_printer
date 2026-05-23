import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

class CountdownMode extends StatefulWidget {
  final VoidCallback onBack;
  const CountdownMode({super.key, required this.onBack});

  @override
  State<CountdownMode> createState() => _CountdownModeState();
}

class _CountdownModeState extends State<CountdownMode> {
  final _labelController = TextEditingController();
  DateTime? _targetDate;
  bool _isPrinting = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  int _daysUntil(DateTime target) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final t = DateTime(target.year, target.month, target.day);
    return t.difference(today).inDays;
  }

  String _headlineText(int days) {
    if (days == 0) return 'TODAY';
    if (days > 0) return '$days';
    return '${days.abs()}';
  }

  String _subText(int days) {
    if (days == 0) return "IT'S TODAY!";
    if (days == 1) return 'DAY UNTIL';
    if (days > 1) return 'DAYS UNTIL';
    if (days == -1) return 'DAY AGO';
    return 'DAYS AGO';
  }

  Future<void> _print() async {
    if (_targetDate == null) return;
    final label = _labelController.text.trim();
    final days = _daysUntil(_targetDate!);
    final dateStr =
        DateFormat('MMM d, yyyy').format(_targetDate!);

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Countdown: ${label.isNotEmpty ? label : dateStr}',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.hr();
        bytes += g.emptyLines(1);

        if (days == 0) {
          bytes += g.text(
            'TODAY!',
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.center,
            ),
          );
        } else {
          bytes += g.text(
            _headlineText(days),
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.center,
            ),
          );
          bytes += g.text(
            _subText(days),
            styles: const PosStyles(
              bold: true,
              align: PosAlign.center,
            ),
          );
        }

        if (label.isNotEmpty) {
          bytes += g.emptyLines(1);
          bytes += g.text(
            label.toUpperCase(),
            styles: const PosStyles(
              bold: true,
              align: PosAlign.center,
            ),
          );
        }

        bytes += g.emptyLines(1);
        bytes += g.text(
          dateStr,
          styles: const PosStyles(align: PosAlign.center),
        );

        bytes += g.emptyLines(1);
        bytes += g.hr();
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _targetDate != null ? _daysUntil(_targetDate!) : null;
    final label = _labelController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'COUNTDOWN', onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _labelController,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.spaceMono(fontSize: 14),
                  decoration:
                      funInputDecoration('Event label', hint: 'Summer Vacation')
                          .copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Date picker row
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _targetDate != null
                            ? Colors.black
                            : Colors.black26,
                        width: _targetDate != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          _targetDate != null
                              ? DateFormat('MMM d, yyyy').format(_targetDate!)
                              : 'Pick a date',
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            color: _targetDate != null
                                ? Colors.black
                                : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Preview
                if (days != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        if (days == 0)
                          Text(
                            'TODAY!',
                            style: GoogleFonts.spaceMono(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else ...[
                          Text(
                            _headlineText(days),
                            style: GoogleFonts.spaceMono(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subText(days),
                            style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        if (label.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            label.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(_targetDate!),
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            color: Colors.black38,
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
          onPrint: _targetDate == null ? null : _print,
        ),
      ],
    );
  }
}
