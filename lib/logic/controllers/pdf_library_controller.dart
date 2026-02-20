import 'package:flutter/material.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/data/repositories/pdf_repository.dart';

class PdfLibraryController extends ChangeNotifier {
  final PdfRepository _repository = PdfRepository();
  List<PdfFileModel> _allFiles = [];
  List<PdfFileModel> _filteredFiles = [];
  bool isLoading = true;
  String _searchQuery = '';

  //
  List<PdfFileModel> get allFiles => _filteredFiles;
  // to
  List<PdfFileModel> get favouriteFiles =>
      _filteredFiles.where((f) => f.isFavorite).toList();

  // to get recent files
  List<PdfFileModel> get recentFiles {
    final recent = _filteredFiles.where((f) => f.lastOpened != null).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    return recent;
  }

  // to load all pdfs
  Future<void> loadPdfs() async {
    try {
      isLoading = true;
      notifyListeners();
      _allFiles = await _repository.loadAllPdfs();
      _applySearch();
      isLoading = false;
      notifyListeners();
    } catch (_) {}
  }

  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredFiles = List.from(_allFiles);
    } else {
      _filteredFiles = _allFiles
          .where(
            (f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
  }
}
