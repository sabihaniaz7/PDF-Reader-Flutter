import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/data/models/sort_option.dart';
import 'package:pdf_reader/data/repositories/pdf_repository.dart';
import 'package:pdf_reader/data/repositories/pdf_storage_service.dart';
import 'package:share_plus/share_plus.dart';

/// Controller for managing the library of PDFs found on the device.
///
/// Handles scanning, searching, sorting, and persistent state (favorites/recents)
/// for all PDF files. It uses [PdfRepository] for file operations and
/// [PdfStorageService] for local persistence.
class PdfLibraryController extends ChangeNotifier {
  final PdfRepository _repository = PdfRepository();
  final PdfStorageService _storage = PdfStorageService();

  /// The master list containing every PDF file found on the device.
  List<PdfFileModel> _allFiles = [];

  /// A subset of [_allFiles] that matches the current search query.
  List<PdfFileModel> _filteredFiles = [];

  /// Indicates if a full device scan is currently in progress.
  bool isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newestFirst;

  SortOption get sortOption => _sortOption;

  // -----------GETTERS-----------

  /// Returns the current list of PDFs, sorted according to user preference.
  List<PdfFileModel> get allFiles => _sortedList(_filteredFiles);

  /// Returns only the PDFs marked as favorites, sorted.
  List<PdfFileModel> get favouriteFiles =>
      _sortedList(_filteredFiles).where((f) => f.isFavorite).toList();

  /// Returns PDFs that have been opened, sorted by the most recently opened.
  List<PdfFileModel> get recentFiles {
    final recent = _filteredFiles.where((f) => f.lastOpened != null).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    return recent;
  }

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Bootstraps the library state on app launch.
  ///
  /// If the device has been scanned before, it loads instantly from cache.
  /// Otherwise, it performs a full initial device scan.
  Future<void> init({BuildContext? context}) async {
    final alreadyScanned = await _storage.hasScannedOnce();
    if (context != null && !context.mounted) return;

    if (alreadyScanned) {
      // Fast path: load from SharedPreferences.
      await loadFromStorage();
    } else {
      // First launch or cleared data: scan physical storage.
      await _scanDevice(context: context);
    }
  }

  /// Loads the PDF metadata list from local SharedPreferences.
  Future<void> loadFromStorage() async {
    try {
      _allFiles = await _storage.loadPdfList();
    } catch (_) {
      _allFiles = [];
    }
    _applySearch();
    notifyListeners();
  }

  /// Scans the entire device storage for .pdf files.
  ///
  /// Merges existing user states (favorites/recents) into the new scan results
  /// to ensure data is not lost when the file system changes.
  Future<void> _scanDevice({BuildContext? context}) async {
    isLoading = true;
    notifyListeners();
    try {
      final scanned = await _repository.loadAllPdfs();

      // Load saved preferences to merge into new results.
      final saved = await _storage.loadPdfList();
      final savedMap = {for (final f in saved) f.path: f};

      _allFiles = scanned.map((f) {
        final s = savedMap[f.path];
        // If we have saved state for this path, restore it.
        return s != null ? f.withSavedState(s) : f;
      }).toList();

      // Persist the merged list to cache.
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

  /// Forces a fresh scan of the device to find newly added or removed files.
  Future<void> refreshPdfs({BuildContext? context}) async {
    await _scanDevice(context: context);
  }

  /// Filters the library list based on a search string.
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Internal helper to sync [_filteredFiles] with [_allFiles] based on query.
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

  /// Updates the global sorting preference.
  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  /// Returns a new sorted list based on the active [SortOption].
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

  /// Toggles the 'favorite' status of a PDF and persists immediately.
  void toggleFavorite(PdfFileModel file, {BuildContext? context}) {
    try {
      file.isFavorite = !file.isFavorite;
      notifyListeners();
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

  /// Records the 'last opened' timestamp for a file and persists immediately.
  void markOpened(PdfFileModel file, {BuildContext? context}) {
    try {
      file.lastOpened = DateTime.now();
      notifyListeners();
      _storage.updateFileState(file);
    } catch (_) {
      // Silent — not critical enough for a snackbar
    }
  }

  /// Deletes a file from both the physical storage and the local metadata cache.
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

  /// Shares a PDF file using the platform's native share sheet.
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

/// Controller for managing the state of a specific PDF document viewer.
///
/// Tracks page progression, night mode settings, and UI visibility within
/// the [PdfViewerScreen].
class PdfViewerController extends ChangeNotifier {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isSearchBarVisible = false;

  /// Defaults to Light Mode as per user request.
  bool _isNightMode = false;

  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isSearchBarVisible => _isSearchBarVisible;
  bool get isNightMode => _isNightMode;

  /// Updates the total number of pages in the current document.
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

  /// Updates the zero-indexed current page (stored as 1-indexed here).
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

  /// Toggles between light and dark rendering for the PDF content.
  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    notifyListeners();
  }

  /// Toggles visibility of the typing/search bar at the bottom.
  void toggleSearchBar() {
    _isSearchBarVisible = !_isSearchBarVisible;
    notifyListeners();
  }

  /// Explicitly hides the bottom bar.
  void hideSearchBar() {
    _isSearchBarVisible = false;
    notifyListeners();
  }
}
