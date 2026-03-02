import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static late SharedPreferences _prefs;

  // Keys
  static const String printerOptionKey = 'saved_printer_option';
  static const String leadingFeedKey = 'saved_leading_paper_feed';
  static const String trailingFeedKey = 'saved_trailing_paper_feed';

  /// Must be called before using any getters
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Ensure required values exist
    if (!_prefs.containsKey(printerOptionKey)) {
      await _prefs.setString(printerOptionKey, "58mm");
    }

    if (!_prefs.containsKey(leadingFeedKey)) {
      await _prefs.setDouble(leadingFeedKey, 0);
    }

    if (!_prefs.containsKey(trailingFeedKey)) {
      await _prefs.setDouble(trailingFeedKey, 0);
    }
  }

  // Safe Getters (NO nulls ever)
  static bool get is58mm =>
      _prefs.getString(printerOptionKey) == "58mm";

  static double get leadingFeed =>
      _prefs.getDouble(leadingFeedKey)!;

  static double get trailingFeed =>
      _prefs.getDouble(trailingFeedKey)!;

  // Setters
  static Future<void> setPrinterOption(bool is58mm) async {
    await _prefs.setString(
        printerOptionKey, is58mm ? "58mm" : "80mm");
  }

  static Future<void> setLeadingFeed(double value) async {
    await _prefs.setDouble(leadingFeedKey, value);
  }

  static Future<void> setTrailingFeed(double value) async {
    await _prefs.setDouble(trailingFeedKey, value);
  }
}