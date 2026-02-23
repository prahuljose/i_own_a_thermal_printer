import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 25),
      child: Text(
        textAlign: TextAlign.center,
        "Great. You have a thermal printer 🖨. Now go explore.️",
        style: GoogleFonts.spaceMono(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black
        ),
      ),)
    );
  }
}
