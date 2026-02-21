import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/data/models/sort_option.dart';
import 'package:pdf_reader/data/repositories/pdf_repository.dart';
import 'package:pdf_reader/data/repositories/pdf_storage_service.dart';
import 'package:share_plus/share_plus.dart';

class PdfLibraryController extends ChangeNotifier {
  final PdfRepository _repository = PdfRepository();
  final PdfStorageService _storage = PdfStorageService();

  List<PdfFileModel> _allFiles = [];
  List<PdfFileModel> _filteredFiles = [];
  // isLoading = true only on very first launch (scanning)
  // subsequent opens load from cache instantly → isLoading stays false
  bool isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newestFirst;
  SortOption get sortOption => _sortOption;

  // -----------GETTERS-----------
  // to get all files
  List<PdfFileModel> get allFiles => _sortedList(_filteredFiles);
  // to get favourite files
  List<PdfFileModel> get favouriteFiles =>
      _sortedList(_filteredFiles).where((f) => f.isFavorite).toList();

  // to get recent files
  List<PdfFileModel> get recentFiles {
    final recent = _filteredFiles.where((f) => f.lastOpened != null).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    return recent;
  }

  // ── Initialise ────────────────────────────────────────────────────────────
  // Strategy:
  //   First ever launch  → show loader → scan device → save to storage
  //   Every later launch → load from storage instantly (no loader, no rescan)
  //   User can manually refresh via refreshPdfs()
  Future<void> init({BuildContext? context}) async {
    final alreadyScanned = await _storage.hasScannedOnce();
    if (context != null && !context.mounted) return;
    if (alreadyScanned) {
      // Fast path: load from local storage, no scanning, no loader
      await loadFromStorage();
    } else {
      // First launch: scan the device
      await _scanDevice(context: context);
    }
  }
  // ── Load from local storage (instant) ─────────────────────────────────────

  Future<void> loadFromStorage() async {
    try {
      _allFiles = await _storage.loadPdfList();
    } catch (_) {
      _allFiles = [];
    }
    _applySearch();
    notifyListeners();
  }
  // ── Scan device (first launch or manual refresh) ───────────────────────────

  Future<void> _scanDevice({BuildContext? context}) async {
    isLoading = true;
    notifyListeners();
    try {
      final scanned = await _repository.loadAllPdfs();
      // Merge saved state (favourites, lastOpened) into freshly scanned list

      final saved = await _storage.loadPdfList();
      final savedMap = {for (final f in saved) f.path: f};

      _allFiles = scanned.map((f) {
        final s = savedMap[f.path];
        return s != null ? f.withSavedState(s) : f;
      }).toList();
      // Persist the merged list
      _applySearch();
      await _storage.savePdfList(_allFiles);
    } catch (_) {
      _allFiles = [];
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          'Could not scan PDFs. Please check storage permissions.',
        );
      }
    }
    _applySearch();
    isLoading = false;
    notifyListeners();
  }
  // ── Manual refresh (pull-to-refresh or refresh button) ────────────────────

  Future<void> refreshPdfs({BuildContext? context}) async {
    await _scanDevice(context: context);
  }

  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    try {
      if (_searchQuery.isEmpty) {
        _filteredFiles = List.from(_allFiles);
      } else {
        _filteredFiles = _allFiles
            .where(
              (f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }
    } catch (_) {
      _filteredFiles = List.from(_allFiles);
    }
  }
  // ── Sort option ────────────────────────────────────────────────────────────

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }
  // ── Sorting ────────────────────────────────────────────────────────────────

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
    } catch (_) {
      // Return unsorted on error — silent, no snackbar needed here
    }
    return sorted;
  }
  // ── Favorite ────────────────────────────────────────────────────────────────

  void toggleFavorite(PdfFileModel file, {BuildContext? context}) {
    try {
      file.isFavorite = !file.isFavorite;
      notifyListeners();
      // Persist the change immediately
      _storage.updateFileState(file);
    } catch (_) {
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          'Could not update favorite. Please try again.',
        );
      }
    }
  }
  // ── Mark opened (Recent files) ───────────────────────────────────────────────

  void markOpened(PdfFileModel file, {BuildContext? context}) {
    try {
      file.lastOpened = DateTime.now();
      notifyListeners();
      // Persist the last opened timestamp immediately
      _storage.updateFileState(file);
    } catch (_) {
      // Silent — not critical enough for a snackbar
    }
  }
  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<bool> deleteFile(PdfFileModel file, {BuildContext? context}) async {
    try {
      final success = await _repository.deleteFile(file.path);
      if (success) {
        _allFiles.remove(file);
        _applySearch();
        notifyListeners();
        // Re save the list of files without the deleted file
        await _storage.savePdfList(_allFiles);
      }
      return success;
    } catch (_) {
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          'Could not delete "${file.name}". Please try again.',
        );
      }
      return false;
    }
  }
  // ── Share ───────────────────────────────────────────────────────────────────

  Future<void> shareFile(PdfFileModel file, {BuildContext? context}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: file.name),
      );
    } catch (_) {
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          'Could not share "${file.name}". Please try again.',
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF Viewer Controller
// ─────────────────────────────────────────────────────────────────────────────

class PdfViewerController extends ChangeNotifier {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isSearchBarVisible = false;
  bool _isNightMode = true;

  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isSearchBarVisible => _isSearchBarVisible;
  bool get isNightMode => _isNightMode;

  void setTotalPages(int pages, {BuildContext? context}) {
    try {
      _totalPages = pages;
      notifyListeners();
    } catch (_) {
      if (context != null && context.mounted) {
        showAppSnackBar(context, 'Could not load page count.');
      }
    }
  }

  void setCurrentPage(int page, {BuildContext? context}) {
    try {
      _currentPage = page + 1;
      notifyListeners();
    } catch (_) {
      if (context != null && context.mounted) {
        showAppSnackBar(context, 'Could not update page number.');
      }
    }
  }

  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    notifyListeners();
  }

  void toggleSearchBar() {
    _isSearchBarVisible = !_isSearchBarVisible;
    notifyListeners();
  }

  void hideSearchBar() {
    _isSearchBarVisible = false;
    notifyListeners();
  }
}
