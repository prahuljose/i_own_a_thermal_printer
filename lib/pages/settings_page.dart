import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_own_a_thermal_printer/widgets/app_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppPreferences.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _sectionLabel("PAPER ROLL", Icons.straighten_outlined),
          const SizedBox(height: 10),
          _paperWidthCard(),
          const SizedBox(height: 28),
          _sectionLabel("FEED BUFFERS", Icons.space_bar_outlined),
          const SizedBox(height: 10),
          _feedCard(
            label: "Leading Feed",
            description: "Blank lines printed before content.",
            value: AppPreferences.leadingFeed,
            onChanged: (v) {
              AppPreferences.setLeadingFeed(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          _feedCard(
            label: "Trailing Feed",
            description: "Blank lines printed after content.",
            value: AppPreferences.trailingFeed,
            onChanged: (v) {
              AppPreferences.setTrailingFeed(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 28),
          _aboutCard(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _paperWidthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Roll Width",
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Select the paper roll width for your printer.",
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.black45,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment: AppPreferences.is58mm
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (AppPreferences.is58mm) return;
                          AppPreferences.setPrinterOption(true);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            _snackBar("58mm roll width set"),
                          );
                        },
                        child: Center(
                          child: Text(
                            "58MM",
                            style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: AppPreferences.is58mm
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!AppPreferences.is58mm) return;
                          AppPreferences.setPrinterOption(false);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            _snackBar("80mm roll width set"),
                          );
                        },
                        child: Center(
                          child: Text(
                            "80MM",
                            style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: AppPreferences.is58mm
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedCard({
    required String label,
    required String description,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final intVal = value.toInt();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: intVal == 0 ? Colors.black12 : Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$intVal",
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: intVal == 0 ? Colors.black45 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.black45,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.black12,
              thumbColor: Colors.black,
              overlayColor: Colors.black.withValues(alpha: 0.08),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: 0,
              max: 5,
              divisions: 5,
              value: value,
              onChanged: onChanged,
              onChangeEnd: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => Text(
                  "$i",
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: intVal == i ? Colors.black : Colors.black26,
                    fontWeight: intVal == i
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.print_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "I Own a Thermal Printer",
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                "v1.0.0 · That's hot 🥵",
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 1),
      );
}
