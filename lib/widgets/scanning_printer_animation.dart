
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanningIndicator extends StatefulWidget {
  const ScanningIndicator({super.key});

  @override
  State<ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<ScanningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FadeTransition(
        //   opacity: _controller,
        //   child: const Icon(
        //     Icons.bluetooth_searching,
        //     size: 36,
        //     color: Colors.black,
        //   ),
        // ),
        const SizedBox(height: 16),
        BlinkingText(),
      ],
    );
  }
}

class BlinkingText extends StatefulWidget {
  @override
  State<BlinkingText> createState() => BlinkingTextState();
}

class BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        FadeTransition(
          opacity: _cursorController,
          child: Text(
            "> SCANNING FOR DEVICES_",
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}