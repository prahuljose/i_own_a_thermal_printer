import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Back-button header shared by every Fun Mode tool.
class FunHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const FunHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: onBack,
            color: Colors.black,
          ),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard black print button used at the bottom of every tool.
class FunPrintButton extends StatelessWidget {
  final bool isPrinting;
  final VoidCallback? onPrint;

  const FunPrintButton({
    super.key,
    required this.isPrinting,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ElevatedButton.icon(
        onPressed: isPrinting ? null : onPrint,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black26,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        icon: isPrinting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.print_rounded, size: 18),
        label: Text(
          isPrinting ? 'PRINTING...' : 'PRINT',
          style: GoogleFonts.spaceMono(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Uniform text field style.
InputDecoration funInputDecoration(String label, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black45),
      hintStyle: GoogleFonts.spaceMono(fontSize: 12, color: Colors.black26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
