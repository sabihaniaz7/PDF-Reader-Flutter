/// Defines the available criteria for sorting the PDF list.
enum SortOption {
  /// Alphabetical order (Case-insensitive).
  nameAZ,

  /// Reverse alphabetical order.
  nameZA,

  /// Sort by modification date (most recently modified at top).
  newestFirst,

  /// Sort by modification date (oldest at top).
  oldestFirst,

  /// Sort by file size (largest files at top).
  largestFirst,

  /// Sort by file size (smallest files at top).
  smallestFirst,
}

/// Utility extension to provide human-readable display labels for the UI.
extension SortOptionLabel on SortOption {
  /// Returns a user-friendly string representation of the sort option.
  String get label {
    switch (this) {
      case SortOption.nameAZ:
        return 'Name (A → Z)';
      case SortOption.nameZA:
        return 'Name (Z → A)';
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.largestFirst:
        return 'Largest First';
      case SortOption.smallestFirst:
        return 'Smallest First';
    }
  }
}
