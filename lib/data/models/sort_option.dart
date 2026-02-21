enum SortOption {
  nameAZ,
  nameZA,
  newestFirst,
  oldestFirst,
  largestFirst,
  smallestFirst,
}

extension SortOptionLabel on SortOption {
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
