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
}
