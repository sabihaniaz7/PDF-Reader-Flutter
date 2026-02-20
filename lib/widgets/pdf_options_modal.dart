import 'package:flutter/material.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';

class PdfOptionsModal extends StatelessWidget {
  final PdfFileModel file;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onViewInfo;
  final VoidCallback onToggleFavorites;

  const PdfOptionsModal({
    super.key,
    required this.file,
    required this.onShare,
    required this.onDelete,
    required this.onViewInfo,
    required this.onToggleFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
