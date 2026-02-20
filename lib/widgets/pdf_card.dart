import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';

class PdfCard extends StatelessWidget {
  final PdfFileModel file;
  final VoidCallback onTap;
  final VoidCallback onThreeDotsTap;

  const PdfCard({
    super.key,
    required this.file,
    required this.onTap,
    required this.onThreeDotsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const .symmetric(
          horizontal: AppDimensions.cardMarginH,
          vertical: AppDimensions.cardMarginV,
        ),
        padding: const .all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: .circular(AppDimensions.cardBorderRadius),
        ),
        child: Row(
          children: [
            // PDF Icon with red border
            Container(
              width: AppDimensions.iconContainerSize,
              height: AppDimensions.iconContainerSize,
              decoration: BoxDecoration(
                color: AppColors.pdfIconBackground,
                borderRadius: .circular(
                  AppDimensions.iconContainerBorderRadius,
                ),
                border: .all(
                  color: AppColors.pdfIconBorder,
                  width: AppDimensions.iconContainerBorderWidth,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.pdfIconColor,
                  size: AppDimensions.pdfIconSize,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    file.name,
                    style: AppTextStyles.cardFileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${file.size} • ${file.lastModified}',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Three dots menu
            GestureDetector(
              onTap: onThreeDotsTap,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.more_vert,
                  color: AppColors.secondaryText,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
