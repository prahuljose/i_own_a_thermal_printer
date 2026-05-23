import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/fun_print_helper.dart';
import '../../services/image_utils.dart';
import '../../widgets/app_preferences.dart';
import 'shared_widgets.dart';

class PolaroidMode extends StatefulWidget {
  final VoidCallback onBack;
  const PolaroidMode({super.key, required this.onBack});

  @override
  State<PolaroidMode> createState() => _PolaroidModeState();
}

class _PolaroidModeState extends State<PolaroidMode> {
  Uint8List? _imageBytes;
  final _captionController = TextEditingController();
  bool _isPrinting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<void> _print() async {
    if (_imageBytes == null) return;
    final caption = _captionController.text.trim();
    final targetWidth = AppPreferences.is58mm ? 384 : 576;

    await runFunPrint(
      context: context,
      setLoading: (v) => setState(() => _isPrinting = v),
      isMounted: () => mounted,
      historyPreview: 'Polaroid${caption.isNotEmpty ? ': $caption' : ''}',
      buildBytes: (g) async {
        final prepared = await prepareImageForPrint(
          _imageBytes!,
          targetWidth,
          maxHeight: 600,
        );
        if (prepared == null) throw Exception('Image decode failed');

        var bytes = <int>[];
        bytes += g.reset();
        bytes += g.feed(1);
        bytes += g.imageRaster(prepared);
        bytes += g.feed(2);

        if (caption.isNotEmpty) {
          bytes += g.text(
            caption,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
            ),
          );
          bytes += g.emptyLines(1);
        }
        bytes += g.hr();
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
        FunHeader(title: 'POLAROID', onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image area
                GestureDetector(
                  onTap: _isPrinting
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _imageBytes != null
                            ? Colors.black26
                            : Colors.black26,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: Colors.black26),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to pick a photo',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                if (_imageBytes != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _isPrinting
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 14),
                        label: Text('Gallery',
                            style: GoogleFonts.spaceMono(fontSize: 11)),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.black54),
                      ),
                      TextButton.icon(
                        onPressed: _isPrinting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 14),
                        label: Text('Camera',
                            style: GoogleFonts.spaceMono(fontSize: 11)),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.black54),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                TextField(
                  controller: _captionController,
                  maxLength: 40,
                  style: GoogleFonts.spaceMono(fontSize: 14),
                  decoration: funInputDecoration(
                    'Caption (optional)',
                    hint: 'Summer 2025',
                  ).copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 4),
                if (_imageBytes != null)
                  // Mini polaroid preview
                  Center(
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.memory(_imageBytes!,
                                fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _captionController.text.trim().isEmpty
                                ? ' '
                                : _captionController.text.trim(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        FunPrintButton(
          isPrinting: _isPrinting,
          onPrint: _imageBytes == null ? null : _print,
        ),
      ],
    );
  }
}
