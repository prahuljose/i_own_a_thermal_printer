import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    getRollWidthOption();
    _loadPaperFeedValues();
  }

  bool currentOptionIs58mm = true;
  double leadingPaperFeed = 0;
  double trailingPaperFeed = 0;

  Future<void> _loadPaperFeedValues() async {
    final prefs = await SharedPreferences.getInstance();
    final leading = prefs.getDouble('saved_leading_paper_feed');
    final trailing = prefs.getDouble('saved_trailing_paper_feed');

    if (!mounted) return;

    setState(() {
      if (leading == null) {
        prefs.setDouble('saved_leading_paper_feed', 0);
        leadingPaperFeed = 0;
      } else {
        leadingPaperFeed = leading;
      }

      if (trailing == null) {
        prefs.setDouble('saved_trailing_paper_feed', 0);
        trailingPaperFeed = 0;
      } else {
        trailingPaperFeed = trailing;
      }
    });
  }

  Future<void> _setPaperFeedValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_leading_paper_feed', leadingPaperFeed);
    await prefs.setDouble('saved_trailing_paper_feed', trailingPaperFeed);
  }

  Future<void> getRollWidthOption() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOption = prefs.getString('saved_printer_option');

    if (!mounted) return;

    setState(() {
      if (savedOption == null) {
        currentOptionIs58mm = true;
        prefs.setString('saved_printer_option', "58mm");
      } else {
        currentOptionIs58mm = savedOption == "58mm";
      }
    });
  }

  Future<void> setOption() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_printer_option');

    if (currentOptionIs58mm) {
      await prefs.setString('saved_printer_option', "58mm");
    } else {
      await prefs.setString('saved_printer_option', "80mm");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 32),
        child: ListView(
          children: [
            const Divider(color: Colors.black, thickness: 1.5, height: 50),
            Text(
              "Roll Width:",
              style: GoogleFonts.spaceMono(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),

            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Sliding black indicator
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    alignment: currentOptionIs58mm
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 32 - 1.5,
                      // subtract padding & divider thickness if needed
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  // Tap layer
                  Row(
                    children: [
                      // 58MM
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!currentOptionIs58mm) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.black,
                                  elevation: 0,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Colors.white12,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  content: Text(
                                    "58mm roll width set",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            setState(() {
                              currentOptionIs58mm = true;
                            });
                            setOption();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "58MM",
                              style: GoogleFonts.spaceMono(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: currentOptionIs58mm
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 80MM
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (currentOptionIs58mm) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.black,
                                  elevation: 0,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Colors.white12,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  content: Text(
                                    "80mm roll width set",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }

                            setState(() {
                              currentOptionIs58mm = false;
                            });
                            setOption();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "80MM",
                              style: GoogleFonts.spaceMono(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: currentOptionIs58mm
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
            const Divider(color: Colors.black, thickness: 1.5, height: 50),
            Text(
              "Leading Feed Buffer:",
              style: GoogleFonts.spaceMono(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                color: Colors.black,
              ),
            ),
            Text(
              "How much extra blank paper needs to be printed first.",
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.black,
                          inactiveTrackColor: Colors.black26,
                          thumbColor: Colors.black,
                          overlayColor: Colors.black12,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: 5,
                          divisions: 5,
                          value: leadingPaperFeed,
                          onChanged: (value) {
                            setState(() {
                              leadingPaperFeed = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _setPaperFeedValues();
                          },
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        "Leading Feed ${leadingPaperFeed.toInt()}",
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            //SizedBox(height: 20),
            const Divider(color: Colors.black, thickness: 1.5, height: 50),
            Text(
              "Trailing Feed Buffer:",
              style: GoogleFonts.spaceMono(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                color: Colors.black,
              ),
            ),
            Text(
              "How much extra blank paper needs to be printed at the end.",
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.black,
                          inactiveTrackColor: Colors.black26,
                          thumbColor: Colors.black,
                          overlayColor: Colors.black12,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: 5,
                          divisions: 5,
                          value: trailingPaperFeed,
                          onChanged: (value) {
                            setState(() {
                              trailingPaperFeed = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _setPaperFeedValues();
                          },
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        "Trailing Feed ${trailingPaperFeed.toInt()}",
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black, thickness: 1.5, height: 50),
          ],
        ),
      ),
    );
  }
}
