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

// ----------------------------------------------------------
class _PdfViewerBody extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const _PdfViewerBody({required this.pdfPath, required this.pdfName});

  @override
  State<_PdfViewerBody> createState() => _PdfViewerBodyState();
}

class _PdfViewerBodyState extends State<_PdfViewerBody> {
  PDFViewController? _pdfController;
  final TextEditingController _jumpController = TextEditingController();

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }
  // ── Jump to page dialog ───────────────────────────────────────────────────

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
            hintText: 'page (1 - ${ctrl.totalPages})',
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
                } else {
                  showAppSnackBar(
                    context,
                    'Enter a page Between 1 and ${ctrl.totalPages}.',
                  );
                }
              } catch (_) {
                showAppSnackBar(
                  context,
                  'Invalid page number. Please enter a number.',
                );
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

  // ----------- Build------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerController>(
      builder: (context, ctrl, _) {
        final isNight = ctrl.isNightMode;
        final iconColor = isNight
            ? AppColors.primaryText
            : AppColors.cardBackground;

        // Scaffold background flips with night mode
        final bgColor = isNight
            ? AppColors.scaffoldBackground
            : const Color(0xFFF5F5F5);
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isNight
                ? AppColors.scaffoldBackground
                : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: iconColor),
            title: Text(
              widget.pdfName,
              style: AppTextStyles.appBarTitle.copyWith(
                fontSize: 16,
                color: iconColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Light/ Night Mode toggle
              IconButton(
                tooltip: ctrl.isNightMode ? 'Light Mode' : 'Night Mode',
                icon: Icon(
                  ctrl.isNightMode
                      ? Icons.nightlight_round
                      : Icons.wb_sunny_rounded,
                  color: ctrl.isNightMode
                      ? AppColors.nightModeOff
                      : AppColors.nightModeOn,
                ),
                onPressed: ctrl.toggleNightMode,
              ),
              // ── Search bar toggle ───────────────────────────────────────
              IconButton(
                tooltip: 'Copy Text',
                icon: Icon(
                  ctrl.isSearchBarVisible
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                  color: iconColor,
                ),
                onPressed: ctrl.toggleSearchBar,
              ),

              // ── Jump to page ────────────────────────────────────────────
              IconButton(
                tooltip: 'Jump to page',
                icon: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  color: iconColor,
                ),
                onPressed: () => _showJumpToPageDialog(context, ctrl),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── PDF View ───────────────────────────────────────────────
              // swipeHorizontal: false  → vertical scroll (page-by-page)
              // pageFling: true         → snaps to each full page
              // autoSpacing: true       → gap between pages
              // enableSwipe: true       → allows swiping between pages
              //
              // flutter_pdfview scrolls vertically when swipeHorizontal=false.
              // Users swipe up/down to move between pages naturally.
              PDFView(
                filePath: widget.pdfPath,
                enableSwipe: true,
                swipeHorizontal: false, // ← vertical scrolling
                autoSpacing: true,
                pageFling: true, // snap to full page on release
                pageSnap: true, // snap pages into view
                fitPolicy: FitPolicy.BOTH,
                nightMode: isNight,
                onViewCreated: (c) => _pdfController = c,
                onRender: (pages) {
                  try {
                    ctrl.setTotalPages(pages ?? 0, context: context);
                  } catch (_) {
                    showAppSnackBar(context, 'Could not render PDF pages.');
                  }
                },
                onPageChanged: (page, _) {
                  try {
                    ctrl.setCurrentPage(page ?? 0, context: context);
                  } catch (_) {
                    // Silent — not critical enough to interrupt reading
                  }
                },
                onError: (error) {
                  showAppSnackBar(
                    context,
                    'Could not open this PDF. The file may be corrupted.',
                  );
                },
                onPageError: (page, error) {
                  showAppSnackBar(context, 'Could not load page $page.');
                },
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
                        color: ctrl.isNightMode
                            ? AppColors.pageIndicatorBackground
                            : const Color(0xDDFFFFFF),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.pageIndicatorBorderRadius,
                        ),
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.scaffoldBackground.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${ctrl.currentPage} / ${ctrl.totalPages}',
                        style: AppTextStyles.pageIndicator.copyWith(
                          color: ctrl.isNightMode
                              ? AppColors.primaryText
                              : AppColors.cardBackground,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Search bar — slides up from bottom ────────────────────────
              // NOTE: This searches within PDF text only if the PDF has embedded
              // text. flutter_pdfview renders pages as images, so text search
              // and copy are NOT natively supported in this package.
              // The bar below lets user type and copy their typed text.
              // Copy text bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                bottom: ctrl.isSearchBarVisible ? 0 : -80,
                left: 0,
                right: 0,
                child: _CopyTextBar(isNightMode: ctrl.isNightMode),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy text bar widget —
// ─────────────────────────────────────────────────────────────────────────────

class _CopyTextBar extends StatefulWidget {
  final bool isNightMode;
  const _CopyTextBar({required this.isNightMode});

  @override
  State<_CopyTextBar> createState() => _CopyTextBarState();
}

class _CopyTextBarState extends State<_CopyTextBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barBg = widget.isNightMode ? AppColors.cardBackground : Colors.white;
    final fieldBg = widget.isNightMode
        ? AppColors.searchBarBackground
        : const Color(0xFFF0F0F0);
    final textColor = widget.isNightMode
        ? AppColors.primaryText
        : AppColors.cardBackground;

    return Container(
      color: barBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.secondaryText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor, fontSize: 14),
                  cursorColor: AppColors.pdfIconColor,
                  decoration: InputDecoration(
                    hintText: 'Type text to copy...',
                    hintStyle: AppTextStyles.searchHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            // Copy typed text
            IconButton(
              tooltip: 'Copy to clipboard',
              icon: const Icon(
                Icons.copy_rounded,
                color: AppColors.accentText,
                size: 22,
              ),
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isEmpty) {
                  showAppSnackBar(
                    context,
                    'Type some text first, then tap Copy',
                  );
                  return;
                }
                try {
                  Clipboard.setData(ClipboardData(text: text));
                  showAppSnackBar(
                    context,
                    'Copied to clipboard.',
                    actionLabel: 'OK',
                  );
                } catch (_) {
                  showAppSnackBar(
                    context,
                    'Could not copy text. Please try again.',
                  );
                }
              },
            ),
            // Clear
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.secondaryText,
                size: 20,
              ),
              onPressed: () {
                _controller.clear();
                context.read<PdfViewerController>().hideSearchBar();
              },
            ),
          ],
        ),
      ),
    );
  }
}
