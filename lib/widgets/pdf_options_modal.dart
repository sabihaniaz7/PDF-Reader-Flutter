import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';

class PdfOptionsModal extends StatelessWidget {
  final PdfFileModel file;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onViewInfo;
  final VoidCallback onToggleFavorite;

  const PdfOptionsModal({
    super.key,
    required this.file,
    required this.onShare,
    required this.onDelete,
    required this.onViewInfo,
    required this.onToggleFavorite,
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
          Padding(
            padding: const .symmetric(
              horizontal: AppDimensions.modalPaddingH,
              vertical: 12,
            ),
            child: Row(
              children: [
                //
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.pdfIconBackground,
                    borderRadius: .circular(10),
                    border: .all(color: AppColors.pdfIconBorder, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.pdfIconColor,
                      size: 24,
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
                      const SizedBox(height: 3),
                      Text(
                        '${file.size} • ${file.lastModified}',
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                // Favourite Star
                GestureDetector(
                  onTap: () {
                    onToggleFavorite();
                    Navigator.pop(context);
                  },
                  child: Icon(
                    file.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: file.isFavorite
                        ? AppColors.starActive
                        : AppColors.starInactive,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.dividerColor, height: 1),
          const SizedBox(height: 8),

          // Action Items
          _ModalActionItem(
            icon: Icons.share_rounded,
            iconColor: AppColors.shareColor,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
          _ModalActionItem(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.deleteColor,
            label: 'Delete',
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          _ModalActionItem(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.infoColor,
            label: 'View Info',
            onTap: () {
              Navigator.pop(context);
              onViewInfo();
            },
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ModalActionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ModalActionItem({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.modalPaddingH,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Text(label, style: AppTextStyles.modalActionLabel),
          ],
        ),
      ),
    );
  }
}
