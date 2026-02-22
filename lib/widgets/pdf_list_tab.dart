import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:pdf_reader/widgets/pdf_card.dart';
import 'package:pdf_reader/widgets/pdf_options_modal.dart';

/// A reusable tab view component that displays a scrollable list of [PdfCard]s.
///
/// It includes helper methods for showing file information dialogs,
/// confirmation dialogs for deletion, and managing the state of the list.
class PdfListTab extends StatelessWidget {
  /// The list of PDF files to display in this tab.
  final List<PdfFileModel> files;

  /// Whether a data loading/scanning operation is currently active.
  final bool isLoading;

  /// The message to display if the [files] list is empty.
  final String emptyMessage;

  // Callbacks for file interactions
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

  /// Displays the options modal (bottom sheet) for a specific file.
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

  /// Displays a confirmation dialog before permanently deleting a file.
  void _confirmDelete(BuildContext context, PdfFileModel file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete PDF", style: AppTextStyles.modalTitle),
        content: Text(
          'Delete "${file.name}"? This cannot be undone.',
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
                  showAppSnackBar(
                    context,
                    success
                        ? '"${file.name}" deleted.'
                        : 'Could not delete "${file.name}". Please try again.',
                    actionLabel: 'OK',
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    'Something went wrong while deleting.',
                    actionLabel: 'OK',
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

  /// Displays a dialog containing detailed metadata about the [file].
  void _showInfoDialog(BuildContext context, PdfFileModel file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("File Info", style: AppTextStyles.modalTitle),
        content: SingleChildScrollView(
          child: Column(
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
    // Show a spinner if the tab segments are explicitly loading.
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pdfIconColor),
      );
    }

    // Show an empty state message if no files are found for the current segment.
    if (files.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(
              height: 100,
            ), // Push empty state down for better balance.
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

    // Build the scrollable list of PDF cards.
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
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

/// Internal helper widget to display a labeled metadata row in the Info Dialog.
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
