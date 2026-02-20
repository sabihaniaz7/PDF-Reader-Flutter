class PdfFileModel {
  final String path;
  final String name;
  final String size;
  final String lastModified;
  final String createdDate;
  bool isFavorite;
  DateTime? lastOpened;

  PdfFileModel({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.createdDate,
    this.isFavorite = false,
    this.lastOpened,
  });
}
