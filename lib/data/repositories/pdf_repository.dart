import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfRepository {
  // Request storage permission and return all PDFs from external storage
  Future<List<PdfFileModel>> loadAllPdfs() async {
    final List<PdfFileModel> results = [];

    try {
      PermissionStatus status = await Permission.manageExternalStorage
          .request();
      if (!status.isGranted) {
        return results;
      }
      final dirs = await ExternalPath.getExternalStorageDirectories();
      if (dirs == null || dirs.isEmpty) return results;
      await _scanDirectory(dirs.first, results);
    } catch (_) {}
    return results;
  }

  Future<void> _scanDirectory(
    String dirPath,
    List<PdfFileModel> results,
  ) async {
    try {
      final dir = Directory(dirPath);
      final entities = dir.list(recursive: false);
      await for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          final stat = await entity.stat();
          results.add(
            PdfFileModel(
              path: entity.path,
              name: entity.path.split('/').last,
              size: _formatSize(stat.size),
              lastModified: _formatDate(stat.modified),
              createdDate: _formatDate(stat.changed),
            ),
          );
        } else if (entity is Directory) {
          await _scanDirectory(entity.path, results);
        }
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
