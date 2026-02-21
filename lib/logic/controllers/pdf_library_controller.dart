import 'package:flutter/material.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/data/models/sort_option.dart';
import 'package:pdf_reader/data/repositories/pdf_repository.dart';
import 'package:share_plus/share_plus.dart';

class PdfLibraryController extends ChangeNotifier {
  final PdfRepository _repository = PdfRepository();

  List<PdfFileModel> _allFiles = [];
  List<PdfFileModel> _filteredFiles = [];
  bool isLoading = true;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newestFirst;
  SortOption get sortOption => _sortOption;

  //
  List<PdfFileModel> get allFiles => _sortedList(_filteredFiles);
  // to
  List<PdfFileModel> get favouriteFiles =>
      _sortedList(_filteredFiles).where((f) => f.isFavorite).toList();

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

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  List<PdfFileModel> _sortedList(List<PdfFileModel> list) {
    final sorted = List<PdfFileModel>.from(list);
    try {
      switch (_sortOption) {
        case SortOption.nameAZ:
          sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case SortOption.nameZA:
          sorted.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case SortOption.newestFirst:
          sorted.sort(
            (a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime),
          );
          break;
        case SortOption.oldestFirst:
          sorted.sort(
            (a, b) => a.modifiedDateTime.compareTo(b.modifiedDateTime),
          );
          break;
        case SortOption.largestFirst:
          sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
          break;
        case SortOption.smallestFirst:
          sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
          break;
      }
    } catch (_) {}
    return sorted;
  }

  void toggleFavorite(PdfFileModel file) {
    file.isFavorite = !file.isFavorite;
    notifyListeners();
  }

  void markOpened(PdfFileModel file) {
    file.lastOpened = DateTime.now();
    notifyListeners();
  }

  Future<bool> deleteFile(PdfFileModel file) async {
    final success = await _repository.deleteFile(file.path);
    if (success) {
      _allFiles.remove(file);
      _applySearch();
      notifyListeners();
    }
    return success;
  }

  Future<void> shareFile(PdfFileModel file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: file.name),
    );
  }
}

// PDF Viewer State
class PdfViewerController extends ChangeNotifier {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isSearchVisible = false;
  String _searchText = '';

  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isSearchVisible => _isSearchVisible;
  String get searchText => _searchText;

  void setTotalPages(int pages) {
    try {
      _totalPages = pages;
      notifyListeners();
    } catch (_) {}
  }

  void setCurrentPage(int page) {
    try {
      _currentPage = page + 1;
      notifyListeners();
    } catch (_) {}
  }

  void toggleSearch() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible) {
      _searchText = '';
    }
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }
}
