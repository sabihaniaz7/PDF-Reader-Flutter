import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_file_model.dart';

/// Handles all local persistence using SharedPreferences.
/// Saves:
///   - The full PDF list (so it loads instantly on reopen, no rescan)
///   - Favourite paths (to restore stars)
///   - Recent paths + timestamps (to restore the Recent tab)
///   - A flag marking whether the initial scan has ever completed

class PdfStorageService {
  static const _keyPdfList = 'pdf_list';
  static const _keyScannedOnce = 'scanned_once_v1';

  // ---- Save the full scanned List ----
  Future<void> savePdfList(List<PdfFileModel> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = files.map((f) => jsonEncode(f.toJson())).toList();
      await prefs.setStringList(_keyPdfList, encoded);
      await prefs.setBool(_keyScannedOnce, true);
    } catch (_) {
      //Persistence failure is non-fatal — app still works
    }
  }

  // ---- Load the full scanned List ----
  Future<List<PdfFileModel>> loadPdfList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyPdfList);
      if (raw == null || raw.isEmpty) return [];
      return raw
          .map(
            (s) => PdfFileModel.fromJson(jsonDecode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Check if the first scan has ever run ─────────────────────────────────
  Future<bool> hasScannedOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyScannedOnce) ?? false;
    } catch (_) {
      return false;
    }
  }
  // ── Save mutable state (favourites + recents) into the stored list ────────
  // Called whenever favourite toggled or file opened, so changes persist
  // without requiring a full re-save of the whole list

  Future<void> updateFileState(PdfFileModel file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyPdfList);
      if (raw == null || raw.isEmpty) return;
      final updated = raw.map((s) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map['path'] == file.path) {
          return jsonEncode(file.toJson());
        }
        return s;
      }).toList();
      await prefs.setStringList(_keyPdfList, updated);
    } catch (_) {
      //Persistence failure is non-fatal — app still works
    }
  }

  // ── Clear everything (for testing / reset) ───────────────────────────────
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
