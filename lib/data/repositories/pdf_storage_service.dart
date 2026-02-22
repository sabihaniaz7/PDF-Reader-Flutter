import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_file_model.dart';

/// Handles all local persistence using SharedPreferences.
/// Saves:
///   - The full PDF list (so it loads instantly on reopen, no rescan)
///   - Favourite paths (to restore stars)
///   - Recent paths + timestamps (to restore the Recent tab)
///   - A flag marking whether the initial scan has ever completed

/// Handles all local persistence using [SharedPreferences].
///
/// This service caches the full list of discovered PDF files to enable
/// instant app loading without re-scanning the entire device storage on every launch.
/// It also persists user-specific states like favorites and last opened timestamps.
class PdfStorageService {
  /// Key for storing the serialized list of PDF models.
  static const _keyPdfList = 'pdf_list';

  /// Key for tracking if the first-run scanner has ever successfully completed.
  static const _keyScannedOnce = 'scanned_once_v1';

  /// Saves the full list of [PdfFileModel]s to local storage.
  ///
  /// Also sets the [_keyScannedOnce] flag to true.
  Future<void> savePdfList(List<PdfFileModel> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Serialize each model to a JSON string.
      final encoded = files.map((f) => jsonEncode(f.toJson())).toList();
      await prefs.setStringList(_keyPdfList, encoded);
      await prefs.setBool(_keyScannedOnce, true);
    } catch (_) {
      //Persistence failure is non-fatal — app still works
    }
  }

  /// Retrieves the cached list of PDF files from local storage.
  ///
  /// Returns an empty list if no data is found or an error occurs.
  Future<List<PdfFileModel>> loadPdfList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyPdfList);
      if (raw == null || raw.isEmpty) return [];

      // Deserialize JSON strings back into PdfFileModel instances.
      return raw
          .map(
            (s) => PdfFileModel.fromJson(jsonDecode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Checks if the application has ever completed its initial storage scan.
  ///
  /// This determines whether the app should show a loader and scan the device
  /// or simply load from the local cache.
  Future<bool> hasScannedOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyScannedOnce) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Updates the state of a single PDF file within the stored list.
  ///
  /// Performs an in-place update of the specific file's JSON entry in SharedPreferences.
  /// This is used for persisting 'favorite' toggles and 'last opened' updates
  /// without rewriting the entire scanned list.
  Future<void> updateFileState(PdfFileModel file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyPdfList);
      if (raw == null || raw.isEmpty) return;

      final updated = raw.map((s) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        // Use the absolute path as the unique identifier.
        if (map['path'] == file.path) {
          return jsonEncode(file.toJson());
        }
        return s;
      }).toList();

      await prefs.setStringList(_keyPdfList, updated);
    } catch (_) {
      // Non-fatal
    }
  }

  /// Clears all stored PDF data and reset the scanner flag.
  ///
  /// Primarily used for development or providing a "Factory Reset" option.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPdfList);
      await prefs.remove(_keyScannedOnce);
    } catch (_) {
      //Persistence failure is non-fatal — app still works
    }
  }
}
