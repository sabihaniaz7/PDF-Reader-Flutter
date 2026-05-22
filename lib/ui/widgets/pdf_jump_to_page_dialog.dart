import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';

Future<void> showPdfJumpToPageDialog({
  required BuildContext context,
  required PdfViewerController controller,
  required ValueChanged<int> onPageSelected,
}) async {
  final textController = TextEditingController();
  final isNight = controller.isNightMode;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: isNight
          ? AppColors.cardBackground
          : AppColors.lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        'Go to Page',
        style: AppTextStyles.modalTitle.copyWith(
          color: isNight ? AppColors.primaryText : AppColors.cardBackground,
        ),
      ),
      content: TextField(
        controller: textController,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isNight ? AppColors.primaryText : AppColors.cardBackground,
        ),
        cursorColor: AppColors.pdfIconColor,
        decoration: InputDecoration(
          hintText: 'page (1 - ${controller.totalPages})',
          hintStyle: AppTextStyles.searchHint.copyWith(
            color: AppColors.secondaryText,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isNight ? AppColors.dividerColor : AppColors.accentText,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.pdfIconColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isNight
                  ? AppColors.secondaryText
                  : AppColors.tabLabelActive,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final page = int.tryParse(textController.text.trim());
            if (page == null) {
              showAppSnackBar(
                context,
                'Invalid page number. Please enter a number.',
              );
              return;
            }

            if (page < 1 || page > controller.totalPages) {
              showAppSnackBar(
                context,
                'Enter a page Between 1 and ${controller.totalPages}.',
              );
              return;
            }

            onPageSelected(page);
            Navigator.pop(dialogContext);
          },
          child: const Text(
            'Go',
            style: TextStyle(color: AppColors.pdfIconColor),
          ),
        ),
      ],
    ),
  );

  textController.dispose();
}
