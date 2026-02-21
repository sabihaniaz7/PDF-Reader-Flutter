class PdfFileModel {
  final String path;
  final String name;
  final String size;
  final int sizeBytes;
  final String lastModified;
  final String createdDate;
  final DateTime modifiedDateTime;
  bool isFavorite;
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

  /// Returns a copy with updated mutable fields merged from [saved].
  /// Used to restore favourite/lastOpened after a device rescan.

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
