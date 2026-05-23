import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'I Own a\nThermal Printer.',
            style: GoogleFonts.spaceMono(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'A no-nonsense toolkit for your Bluetooth thermal printer.',
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              color: Colors.black54,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32),

          // Feature sections
          _Section(
            icon: Icons.receipt_long_outlined,
            title: 'Receipt Builder',
            body:
                'Build itemised receipts with quantities, prices, and an optional header image. Auto-calculates the total. Save and reload templates.',
          ),

          _Section(
            icon: Icons.label_outline,
            title: 'Label Maker',
            body:
                'Print clean text labels. Toggle between label text and a live QR code preview of the same content.',
          ),

          _Section(
            icon: Icons.qr_code_2_outlined,
            title: 'QR Codes',
            body:
                'Turn any URL or text into a printable QR code. Optionally include the source text below the code.',
          ),

          _Section(
            icon: Icons.checklist_outlined,
            title: 'To-Do List',
            body:
                'Print a paper to-do list with checkbox squares. Great for quick handoffs, packing lists, or just getting things out of your head.',
          ),

          _Section(
            icon: Icons.auto_awesome_outlined,
            title: 'Fun Mode',
            body:
                'Eight creative tools — rubber stamps, fortune cookies, big text, polaroid photos, sticky notes, name badges, a doodle pad, and countdown cards.',
          ),

          _Section(
            icon: Icons.history_outlined,
            title: 'Print History',
            body:
                'Every print is logged automatically. See what you printed, when you printed it, and clear old entries anytime.',
          ),

          _Section(
            icon: Icons.settings_outlined,
            title: 'Settings',
            body:
                'Set your paper width (58mm or 80mm) and tune the leading and trailing feed buffers so prints come out exactly where you want them.',
          ),

          const SizedBox(height: 8),

          // Tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: Colors.black45),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connect your printer first. Go to Connect Printer in the menu, scan, and tap your device. The app remembers it and reconnects automatically on next launch.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'v1.0.0 · Made with Flutter',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: Colors.black26,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
