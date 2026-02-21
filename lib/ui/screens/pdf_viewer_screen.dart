import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:provider/provider.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.pdfName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PdfViewerController(),
      child: _PdfViewerBody(pdfPath: pdfPath, pdfName: pdfName),
    );
  }
}

class _PdfViewerBody extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const _PdfViewerBody({required this.pdfPath, required this.pdfName});

  @override
  State<_PdfViewerBody> createState() => _PdfViewerBodyState();
}

class _PdfViewerBodyState extends State<_PdfViewerBody> {
  PDFViewController? _pdfController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumpController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _showJumpToPageDialog(BuildContext context, PdfViewerController ctrl) {
    _jumpController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Go to Page', style: AppTextStyles.modalTitle),
        content: TextField(
          controller: _jumpController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.primaryText),
          cursorColor: AppColors.pdfIconColor,
          decoration: InputDecoration(
            hintText: 'Enter page (1 - ${ctrl.totalPages})',
            hintStyle: AppTextStyles.searchHint,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.dividerColor),
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              try {
                final page = int.parse(_jumpController.text.trim());
                if (page >= 1 && page <= ctrl.totalPages) {
                  _pdfController?.setPage(page - 1);
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint('[PdfViewer] jump page parse error: $e');
              }
            },
            child: const Text(
              'Go',
              style: TextStyle(color: AppColors.pdfIconColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.scaffoldBackground,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.primaryText),
            title: ctrl.isSearchVisible
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.primaryText),
                    cursorColor: AppColors.pdfIconColor,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      border: InputBorder.none,
                    ),
                    onChanged: ctrl.setSearchText,
                  )
                : Text(
                    widget.pdfName,
                    style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
            actions: [
              // search in pdf toggle
              IconButton(
                icon: Icon(
                  ctrl.isSearchVisible
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: AppColors.primaryText,
                ),
                onPressed: () {
                  ctrl.toggleSearch();
                  if (!ctrl.isSearchVisible) _searchController.clear();
                },
              ),
              // Jump to page
              IconButton(
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.primaryText,
                ),
                tooltip: 'Jump to page',
                onPressed: () => _showJumpToPageDialog(context, ctrl),
              ),
            ],
          ),
          body: Stack(
            children: [
              Scrollbar(
                thumbVisibility: true, // Show scrollbar always
                child: PDFView(
                  filePath: widget.pdfPath,
                  pageFling: true,
                  autoSpacing: true,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  nightMode: true,
                  onViewCreated: (controller) {
                    _pdfController = controller;
                  },
                  onRender: (pages) {
                    try {
                      ctrl.setTotalPages(pages ?? 0);
                    } catch (_) {}
                  },
                  onPageChanged: (page, total) {
                    try {
                      ctrl.setCurrentPage(page ?? 0);
                    } catch (_) {}
                  },
                  onError: (error) {
                    debugPrint('[PdfViewer] error: $error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error Loading Pdfs: $error'),
                        backgroundColor: AppColors.deleteColor,
                      ),
                    );
                  },
                ),
              ),

              // ── Page Indicator
              if (ctrl.totalPages > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showJumpToPageDialog(context, ctrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pageIndicatorPaddingH,
                        vertical: AppDimensions.pageIndicatorPaddingV,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pageIndicatorBackground,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.pageIndicatorBorderRadius,
                        ),
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${ctrl.currentPage} / ${ctrl.totalPages}',
                        style: AppTextStyles.pageIndicator,
                      ),
                    ),
                  ),
                ),

              // ── In-PDF Search Bar (slides down when active) ──
              if (ctrl.isSearchVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.searchBarBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14,
                              ),
                              cursorColor: AppColors.pdfIconColor,
                              decoration: const InputDecoration(
                                hintText: 'Search text in PDF...',
                                hintStyle: AppTextStyles.searchHint,
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search,
                                  color: AppColors.secondaryText,
                                  size: 20,
                                ),
                              ),
                              onChanged: ctrl.setSearchText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Copy search text button
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.shareColor,
                          ),
                          tooltip: 'Copy searched text',
                          onPressed: () {
                            if (ctrl.searchText.isNotEmpty) {
                              Clipboard.setData(
                                ClipboardData(text: ctrl.searchText),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Text copied to clipboard'),
                                  backgroundColor: AppColors.snackbarSuccess,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
