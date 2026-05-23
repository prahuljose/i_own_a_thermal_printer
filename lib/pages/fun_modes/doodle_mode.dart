import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../../services/fun_print_helper.dart';
import '../../widgets/app_preferences.dart';
import 'shared_widgets.dart';

class DoodleMode extends StatefulWidget {
  final VoidCallback onBack;
  const DoodleMode({super.key, required this.onBack});

  @override
  State<DoodleMode> createState() => _DoodleModeState();
}

class _DoodleModeState extends State<DoodleMode> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;
  bool _isPrinting = false;
  final GlobalKey _canvasKey = GlobalKey();

  double _strokeWidth = 4.0;

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _current = [d.localPosition];
      _strokes.add(_current!);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current?.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    _current = null;
  }

  void _clear() => setState(() => _strokes.clear());

  Future<img.Image?> _captureCanvas() async {
    final boundary = _canvasKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final uiImage = await boundary.toImage(pixelRatio: 1.0);
    final byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;

    return img.Image.fromBytes(
      uiImage.width,
      uiImage.height,
      byteData.buffer.asUint8List(),
    );
  }

  Future<void> _print() async {
    if (_strokes.isEmpty) return;
    final targetWidth = AppPreferences.is58mm ? 384 : 576;

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Doodle',
      buildBytes: (g) async {
        final captured = await _captureCanvas();
        if (captured == null) throw Exception('Canvas capture failed');

        final resized = img.copyResize(captured, width: targetWidth);
        final gray = img.grayscale(resized);

        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.imageRaster(gray);
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
        FunHeader(title: 'DOODLE PAD', onBack: widget.onBack),

        // Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                'Size',
                style: GoogleFonts.spaceMono(
                    fontSize: 11, color: Colors.black45),
              ),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 2,
                  max: 16,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                  activeColor: Colors.black,
                  inactiveColor: Colors.black12,
                ),
              ),
              GestureDetector(
                onTap: _strokes.isEmpty ? null : _clear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _strokes.isEmpty ? Colors.black12 : Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _strokes.isEmpty
                          ? Colors.black26
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RepaintBoundary(
                key: _canvasKey,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _DoodlePainter(
                      strokes: _strokes,
                      strokeWidth: _strokeWidth,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        FunPrintButton(
          isPrinting: _isPrinting,
          onPrint: _strokes.isEmpty ? null : _print,
        ),
      ],
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double strokeWidth;

  const _DoodlePainter({required this.strokes, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], strokeWidth / 2,
            paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => true;
}
