import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:permission_handler/permission_handler.dart';
// Android-only import guarded at runtime
import 'package:external_path/external_path.dart'
    if (dart.library.html) 'package:pdf_reader/data/repositories/stub_external_path.dart';

class PdfRepository {
  // Request storage permission and return all PDFs from external storage
  Future<List<PdfFileModel>> loadAllPdfs() async {
    final List<PdfFileModel> results = [];

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        PermissionStatus status = await Permission.manageExternalStorage
            .request();
        if (!status.isGranted) {
          // Fallback: try READ permission for older Android
          final read = await Permission.storage.request();
          if (!read.isGranted) return results;
        }
        final dirs = await ExternalPath.getExternalStorageDirectories();
        if (dirs == null || dirs.isEmpty) return results;
        await _scanDirectory(dirs.first, results);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: scan Documents directory
        // flutter_file_dialog or path_provider needed for iOS full access
        // Basic Documents dir scan:
        final docDir = await _getIOSDocumentsPath();
        if (docDir != null) await _scanDirectory(docDir, results);
      }
    } catch (_) {}
    return results;
  }

  Future<String?> _getIOSDocumentsPath() async {
    try {
      // Uses path_provider on iOS
      // import 'package:path_provider/path_provider.dart';
      // final dir = await getApplicationDocumentsDirectory();
      // return dir.path;
      // Stub for now — wire up path_provider if needed
      return null;
    } catch (e) {
      debugPrint('[PdfRepository] iOS path error: $e');
      return null;
    }
  }

  Future<void> _scanDirectory(
    String dirPath,
    List<PdfFileModel> results,
  ) async {
    try {
      final dir = Directory(dirPath);
      final entities = dir.list(recursive: false);
      await for (final entity in entities) {
        try {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
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
            await _scanDirectory(entity.path, results);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

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
