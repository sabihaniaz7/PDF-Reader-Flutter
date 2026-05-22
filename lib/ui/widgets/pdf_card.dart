import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';

/// A visual card representing a single PDF file in a list.
///
/// Displays the PDF icon, filename, size, and last modification date.
/// It provides a tap target for opening the file and a 'more' icon for options.
class PdfCard extends StatelessWidget {
  /// The PDF file metadata to display.
  final PdfFileModel file;

  /// Callback triggered when the entire card is tapped.
  final VoidCallback onTap;

  /// Callback triggered when the three-dots menu icon is tapped.
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
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardMarginH,
          vertical: AppDimensions.cardMarginV,
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
        child: Row(
          children: [
            // ── PDF Icon with stylized container ──────────────────────────
            Container(
              width: AppDimensions.iconContainerSize,
              height: AppDimensions.iconContainerSize,
              decoration: BoxDecoration(
                color: AppColors.pdfIconBackground,
                borderRadius: BorderRadius.circular(
                  AppDimensions.iconContainerBorderRadius,
                ),
                border: Border.all(
                  color: AppColors.pdfIconColor,
                  width: AppDimensions.iconContainerBorderWidth,
                ),
              ),
              child: Center(
                child: Icon(
                  FontAwesomeIcons.filePdf,
                  color: AppColors.pdfIconColor.withValues(alpha: 0.8),
                  size: AppDimensions.pdfIconSize,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── File Information (Name, Size, Date) ───────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

            // ── Options Menu Trigger ──────────────────────────────────────
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
