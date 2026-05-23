import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/db_service.dart';
import '../services/printer_service.dart';
import '../widgets/app_preferences.dart';

/// Shared print runner for all Fun Mode tools.
/// [buildBytes] receives a ready [Generator] and returns the ESC/POS byte list.
Future<void> runFunPrint({
  required BuildContext context,
  required void Function(bool) setLoading,
  required bool Function() isMounted,
  required Future<List<int>> Function(Generator) buildBytes,
  String historyPreview = 'Fun Mode',
}) async {
  HapticFeedback.mediumImpact();
  setLoading(true);

  try {
    final characteristic = await PrinterService.findWritableCharacteristic();
    if (!isMounted()) return;

    if (characteristic == null) {
      setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack("NO PRINTER FOUND"));
      }
      return;
    }

    final profile = await CapabilityProfile.load();
    if (!isMounted()) return;

    final generator = Generator(
      AppPreferences.is58mm ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    final bytes = await buildBytes(generator);
    await PrinterService.sendInChunks(characteristic, bytes);

    if (isMounted()) {
      setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack("PRINTED!"));
      }
    }

    await DbService.addHistory(type: 'label', preview: historyPreview);
  } catch (e) {
    if (isMounted()) {
      setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack("PRINT FAILED"));
      }
    }
  }
}

SnackBar _snack(String text) => SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      duration: const Duration(seconds: 2),
    );
