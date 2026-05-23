import 'dart:math';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/fun_print_helper.dart';
import 'shared_widgets.dart';

const _fortunes = [
  "A smile is worth a thousand words, but a printed receipt is legally binding.",
  "The best time to act was yesterday. The second best time is after this prints.",
  "You will find unexpected joy in the next roll of paper.",
  "A small act of kindness will return to you threefold — possibly with a receipt.",
  "The path you fear most often leads to the reward you want most.",
  "Not all who wander are lost. Some are just looking for a Bluetooth printer.",
  "Your creativity is your most valuable possession. Guard it carefully.",
  "Good things come to those who wait, but only what's left from those who hustle.",
  "A stranger's compliment today will stay with you longer than you expect.",
  "You are wiser than you believe, braver than you feel, and loved more than you know.",
  "Today's inconvenience is tomorrow's funny story.",
  "The universe rewards action. Even small steps count.",
  "Your future is bright — though possibly in grayscale.",
  "Somewhere, someone is thinking about you fondly right now.",
  "The idea you keep dismissing might be your best one.",
  "Rest is not laziness. Recharge before your next big move.",
  "You will soon receive surprising news that changes your plans for the better.",
  "Keep your friends close, your charger closer.",
  "A long-forgotten skill is about to become surprisingly useful.",
  "The obstacle in your path is also the path.",
  "Someone around you needs to hear exactly what you have to say.",
  "Your next great decision will feel obvious once you make it.",
  "Slow down. Not everything worth seeing is on the fastest route.",
  "The thing you've been putting off wants to be finished today.",
  "You are the average of the five people you spend the most time with. Choose wisely.",
  "A risk taken with preparation is not really a risk — it's a plan.",
  "Everything you need is closer than it appears.",
  "The best projects start with a single line.",
  "Curiosity leads to places no map could predict.",
  "Your patience today is an investment in tomorrow's peace.",
  "Help someone without expecting anything in return. The return will surprise you.",
  "The answer you've been looking for is simpler than you think.",
  "You are exactly where you need to be right now.",
  "One kind word costs nothing and changes everything.",
  "What you practice in private, you perform in public.",
  "The version of you from five years ago would be proud.",
  "Not every door needs to be opened. Some walls are features.",
  "You will overcome the thing that has been weighing on you.",
  "The most important conversation you have today will not be the loudest.",
  "Do one thing today that makes tomorrow easier.",
];

class FortuneMode extends StatefulWidget {
  final VoidCallback onBack;
  const FortuneMode({super.key, required this.onBack});

  @override
  State<FortuneMode> createState() => _FortuneModeState();
}

class _FortuneModeState extends State<FortuneMode> {
  final _rng = Random();
  late String _fortune;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _fortune = _fortunes[_rng.nextInt(_fortunes.length)];
  }

  void _newFortune() {
    setState(() {
      String next;
      do {
        next = _fortunes[_rng.nextInt(_fortunes.length)];
      } while (next == _fortune && _fortunes.length > 1);
      _fortune = next;
    });
  }

  Future<void> _print() async {
    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Fortune cookie',
      buildBytes: (g) async {
        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.text(
          '* * * * * * * * * * * *',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += g.emptyLines(1);
        bytes += g.text(
          'YOUR FORTUNE',
          styles: const PosStyles(
            bold: true,
            align: PosAlign.center,
          ),
        );
        bytes += g.emptyLines(1);
        bytes += g.text(
          _fortune,
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += g.emptyLines(1);
        bytes += g.text(
          '* * * * * * * * * * * *',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += g.feed(2);
        bytes += g.cut();
        return bytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FunHeader(title: 'FORTUNE', onBack: widget.onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD600),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '✦',
                            style: GoogleFonts.spaceMono(
                              fontSize: 20,
                              color: const Color(0xFFFFAB00),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _fortune,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '✦',
                            style: GoogleFonts.spaceMono(
                              fontSize: 20,
                              color: const Color(0xFFFFAB00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: OutlinedButton.icon(
            onPressed: _isPrinting ? null : _newFortune,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black, width: 1.5),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.casino_outlined, size: 16),
            label: Text(
              'NEW FORTUNE',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        FunPrintButton(isPrinting: _isPrinting, onPrint: _print),
      ],
    );
  }
}
