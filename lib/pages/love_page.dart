import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LovePage extends StatelessWidget {
  const LovePage({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar / icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.print_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Rahul Jose',
            style: GoogleFonts.spaceMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Made this app because I own a thermal printer\nand wanted something actually worth printing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: Colors.black54,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32),

          // Links
          _LinkTile(
            icon: Icons.code_rounded,
            label: 'GitHub',
            sublabel: 'prahuljose',
            onTap: () => _open('https://github.com/prahuljose'),
          ),
          const SizedBox(height: 10),
          _LinkTile(
            icon: Icons.work_outline_rounded,
            label: 'LinkedIn',
            sublabel: 'prahuljose',
            onTap: () => _open('https://www.linkedin.com/in/prahuljose/'),
          ),
          const SizedBox(height: 10),
          _LinkTile(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            sublabel: '@prahuljose',
            onTap: () => _open('https://www.instagram.com/prahuljose/'),
          ),

          const SizedBox(height: 36),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.black12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'SHOW SOME LOVE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: Colors.black38,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.black12)),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'If this app made your thermal printer\nactually useful — consider giving it a star\non GitHub or leaving a review on the store.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: Colors.black54,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Built with Flutter · ESC/POS · BLE',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.black26,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
