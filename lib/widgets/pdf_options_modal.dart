import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.modalBackground,
        borderRadius: .vertical(top: .circular(AppDimensions.modalTopRadius)),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const .only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: .circular(2),
              ),
            ),
          ),

          // File Header Info Section
        ],
      ),
    );
  }
}
