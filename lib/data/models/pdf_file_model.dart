/// Represents a PDF file metadata and state within the application.
///
/// This model stores both immutable file system metadata (path, name, size)
/// and mutable application state (isFavorite, lastOpened).
class PdfFileModel {
  /// The absolute file path on the device storage.
  final String path;

  /// The display name of the file (usually the filename).
  final String name;

  /// Human-readable file size (e.g., "1.2 MB").
  final String size;

  /// Raw file size in bytes for accurate sorting.
  final int sizeBytes;

  /// Human-readable last modification date from the file system.
  final String lastModified;

  /// The date the file was initially created or discovered.
  final String createdDate;

  /// [DateTime] representation of the file modification for logic operations.
  final DateTime modifiedDateTime;

  /// Application-level state: whether the user has starred this file.
  bool isFavorite;

  /// Application-level state: when the user last viewed this document.
  DateTime? lastOpened;

  PdfFileModel({
    required this.path,
    required this.name,
    required this.size,
    required this.sizeBytes,
    required this.lastModified,
    required this.createdDate,
    required this.modifiedDateTime,
    this.isFavorite = false,
    this.lastOpened,
  });

  // ── JSON serialisation (for SharedPreferences storage) ──────────────────

  /// Converts the model into a map for JSON serialisation.
  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'size': size,
    'sizeBytes': sizeBytes,
    'lastModified': lastModified,
    'createdDate': createdDate,
    'modifiedDateTime': modifiedDateTime.toIso8601String(),
    'isFavorite': isFavorite,
    'lastOpened': lastOpened?.toIso8601String(),
  };

  /// Constructs a model from a JSON map retrieved from storage.
  factory PdfFileModel.fromJson(Map<String, dynamic> json) => PdfFileModel(
    path: json['path'] as String,
    name: json['name'] as String,
    size: json['size'] as String,
    sizeBytes: json['sizeBytes'] as int,
    lastModified: json['lastModified'] as String,
    createdDate: json['createdDate'] as String,
    modifiedDateTime: DateTime.parse(json['modifiedDateTime'] as String),
    isFavorite: json['isFavorite'] as bool,
    lastOpened: json['lastOpened'] != null
        ? DateTime.parse(json['lastOpened'] as String)
        : null,
  );

  /// Returns a copy of the current model with updated mutable fields merged from [saved].
  ///
  /// This is crucial for maintaining user preferences (favorites/recent history)
  /// when the file system is re-scanned and new model instances are created.
  PdfFileModel withSavedState(PdfFileModel saved) => PdfFileModel(
    path: path,
    name: name,
    size: size,
    sizeBytes: sizeBytes,
    lastModified: lastModified,
    createdDate: createdDate,
    modifiedDateTime: modifiedDateTime,
    isFavorite: saved.isFavorite,
    lastOpened: saved.lastOpened,
  );
}
