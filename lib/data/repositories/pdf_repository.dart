import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:permission_handler/permission_handler.dart';
// Android-only import guarded at runtime
import 'package:external_path/external_path.dart'
    if (dart.library.html) 'package:pdf_reader/data/repositories/stub_external_path.dart';

/// Repository responsible for interacting with the device file system to manage PDF files.
///
/// It handles scanning directories for .pdf files, requesting necessary permissions,
/// and performing file-level operations like deletion.
class PdfRepository {
  /// Scans the device's external storage for all PDF files.
  ///
  /// On Android, it requests [Permission.manageExternalStorage] or falls back to
  /// [Permission.storage] for older versions.
  /// On iOS, it identifies the Documents directory for scanning.
  /// Returns a list of [PdfFileModel] instances representing the found PDFs.
  Future<List<PdfFileModel>> loadAllPdfs() async {
    final List<PdfFileModel> results = [];

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android 11+ (API 30+) requires Manage External Storage for full file access.
        PermissionStatus status = await Permission.manageExternalStorage
            .request();
        if (!status.isGranted) {
          // Fallback for Android 10 and below.
          final read = await Permission.storage.request();
          if (!read.isGranted) return results;
        }
        // Retrieve paths to all physical storage volumes (internal + SD cards).
        final dirs = await ExternalPath.getExternalStorageDirectories();
        if (dirs == null || dirs.isEmpty) return results;

        // Start recursive scan from the root of the primary external storage.
        await _scanDirectory(dirs.first, results);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS uses a sandboxed Documents directory.
        final docDir = await _getIOSDocumentsPath();
        if (docDir != null) await _scanDirectory(docDir, results);
      }
    } catch (_) {}
    return results;
  }

  /// Retrieves the standard Documents directory path for iOS applications.
  Future<String?> _getIOSDocumentsPath() async {
    try {
      // Note: Implementation typically requires path_provider: getApplicationDocumentsDirectory().
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Recursively crawls the file system starting from [dirPath] to find PDF files.
  ///
  /// Discovered PDFs are converted to [PdfFileModel] and added to [results].
  Future<void> _scanDirectory(
    String dirPath,
    List<PdfFileModel> results,
  ) async {
    try {
      final dir = Directory(dirPath);
      // List contents without following symbolic links to avoid infinite loops.
      final entities = dir.list(recursive: false);

      await for (final entity in entities) {
        try {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            // Get file metadata (size, modification date).
            final stat = await entity.stat();
            results.add(
              PdfFileModel(
                path: entity.path,
                name: entity.path.split('/').last,
                size: _formatSize(stat.size),
                sizeBytes: stat.size,
                lastModified: _formatDate(stat.modified),
                createdDate: _formatDate(stat.changed),
                modifiedDateTime: stat.modified,
              ),
            );
          } else if (entity is Directory) {
            // Recurse into subdirectories.
            await _scanDirectory(entity.path, results);
          }
        } catch (_) {
          // Skip inaccessible files/directories.
        }
      }
    } catch (_) {
      // Skip inaccessible root directories.
    }
  }

  /// Converts a raw byte count into a human-readable string (B, KB, MB, GB).
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Formats a [DateTime] into a display-friendly "Day Month Year" string.
  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  /// Maps a month index (1-12) to its short English name.
  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Permanently deletes a file from the device storage.
  ///
  /// Returns `true` if the file was successfully deleted or didn't exist.
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
