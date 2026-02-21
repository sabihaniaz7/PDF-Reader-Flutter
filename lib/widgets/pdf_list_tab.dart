import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/widgets/pdf_card.dart';
import 'package:pdf_reader/widgets/pdf_options_modal.dart';

class PdfListTab extends StatelessWidget {
  final List<PdfFileModel> files;
  final bool isLoading;
  final String emptyMessage;
  final Function(PdfFileModel) onFileTap;
  final Function(PdfFileModel) onToggleFavorite;
  final Function(PdfFileModel) onDelete;
  final Function(PdfFileModel) onShare;

  const PdfListTab({
    super.key,
    required this.files,
    required this.isLoading,
    required this.emptyMessage,
    required this.onFileTap,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onShare,
  });
  //
  void _showOptionsModal(BuildContext context, PdfFileModel file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PdfOptionsModal(
        file: file,
        onShare: () => onShare(file),
        onDelete: () => _confirmDelete(context, file),
        onViewInfo: () => _showInfoDialog(context, file),
        onToggleFavorite: () => onToggleFavorite(file),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PdfFileModel file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete PDF", style: AppTextStyles.modalTitle),
        content: Text(
          'Are you sure you want to delete "${file.name}"? This cannot be undone.',
          style: AppTextStyles.modalSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await onDelete(file);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '"${file.name}" deleted successfully'
                            : 'Failed to delete "${file.name}"',
                      ),
                      backgroundColor: success
                          ? AppColors.snackbarDelete
                          : AppColors.deleteColor,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: AppColors.primaryText,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting file: $e'),
                      backgroundColor: AppColors.deleteColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.deleteColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, PdfFileModel file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete PDF", style: AppTextStyles.modalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: "Name", value: file.name),
            _InfoRow(label: "Size", value: file.size),
            _InfoRow(label: "Modified", value: file.lastModified),
            _InfoRow(label: "Created", value: file.createdDate),
            _InfoRow(label: "Path", value: file.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: AppColors.shareColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pdfIconColor),
      );
    }
    if (files.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: AppColors.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: AppTextStyles.emptyStateText),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const .only(top: 8, bottom: 20),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return PdfCard(
          file: file,
          onTap: () => onFileTap(file),
          onThreeDotsTap: () => _showOptionsModal(context, file),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.sectionHeader),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.modalSubtitle.copyWith(
              color: AppColors.accentText,
            ),
          ),
        ],
      ),
    );
  }
}
