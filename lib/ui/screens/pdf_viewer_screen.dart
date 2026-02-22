import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:provider/provider.dart';

/// A dedicated screen for viewing PDF documents.
///
/// It utilizes [flutter_pdfview] for native rendering and includes
/// features like night mode toggling and jump-to-page navigation.
class PdfViewerScreen extends StatelessWidget {
  /// The absolute file path of the PDF to display.
  final String pdfPath;

  /// The display name (filename) of the PDF.
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.pdfName,
  });

  @override
  Widget build(BuildContext context) {
    // Provide a localized controller for managing the viewer's specific state.
    return ChangeNotifierProvider(
      create: (_) => PdfViewerController(),
      child: _PdfViewerBody(pdfPath: pdfPath, pdfName: pdfName),
    );
  }
}

// ----------------------------------------------------------

/// Internal implementation of the PDF viewer UI.
class _PdfViewerBody extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const _PdfViewerBody({required this.pdfPath, required this.pdfName});

  @override
  State<_PdfViewerBody> createState() => _PdfViewerBodyState();
}

class _PdfViewerBodyState extends State<_PdfViewerBody> {
  /// Reference to the underlying PDF view controller provided by the package.
  PDFViewController? _pdfController;

  /// Controller for the numeric input field in the 'Jump to Page' dialog.
  final TextEditingController _jumpController = TextEditingController();
  double _indicatorTop = 12.0;

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  // ── Jump to page dialog ───────────────────────────────────────────────────

  /// Shows an [AlertDialog] prompting the user to enter a specific page number.
  void _showJumpToPageDialog(BuildContext context, PdfViewerController ctrl) {
    _jumpController.clear();
    final isNight = ctrl.isNightMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isNight ? AppColors.cardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Go to Page',
          style: AppTextStyles.modalTitle.copyWith(
            color: isNight ? AppColors.primaryText : AppColors.cardBackground,
          ),
        ),
        content: TextField(
          controller: _jumpController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isNight ? AppColors.primaryText : AppColors.cardBackground,
          ),
          cursorColor: AppColors.pdfIconColor,
          decoration: InputDecoration(
            hintText: 'page (1 - ${ctrl.totalPages})',
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
            onPressed: () => Navigator.pop(context),
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
              try {
                final page = int.parse(_jumpController.text.trim());
                if (page >= 1 && page <= ctrl.totalPages) {
                  // flutter_pdfview is 0-indexed.
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

        // Colors for icons/text switch based on night mode to maintain visibility.
        final iconColor = isNight
            ? AppColors.primaryText
            : AppColors.cardBackground;

        // Scaffold background adapts to night mode.
        final bgColor = isNight ? AppColors.scaffoldBackground : Colors.white;

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
              // ── Night/Light Mode toggle ─────────────────────────────────
              IconButton(
                tooltip: isNight ? 'Light Mode' : 'Night Mode',
                icon: Icon(
                  isNight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isNight
                      ? AppColors.nightModeOff
                      : AppColors.nightModeOn,
                ),
                onPressed: ctrl.toggleNightMode,
              ),

              // ── Bottom search bar toggle ────────────────────────────────
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

              // ── Navigation jump ─────────────────────────────────────────
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bodyHeight = constraints.maxHeight;
              return Stack(
                children: [
                  // ── PDF Rendering Engine ─────────────────────────────────────
                  ColoredBox(
                    color: isNight
                        ? AppColors.scaffoldBackground
                        : AppColors.primaryText,
                    child: PDFView(
                      // We use a ValueKey(isNight) to force a full widget rebuild
                      // when theme changes, as the package may not update the view
                      // color dynamically otherwise.
                      key: ValueKey<bool>(isNight),
                      filePath: widget.pdfPath,
                      // Maintain the user's current page during theme rebuilds.
                      defaultPage: ctrl.currentPage > 0
                          ? ctrl.currentPage - 1
                          : 0,
                      enableSwipe: true,
                      swipeHorizontal:
                          false, // Vertical scrolling for natural reading.
                      autoSpacing: true,
                      pageFling: true, // Swipes snap to the next full page.
                      pageSnap: true,
                      fitPolicy: FitPolicy.BOTH,
                      nightMode: isNight,
                      backgroundColor: isNight
                          ? AppColors.scaffoldBackground
                          : Colors.white,

                      onViewCreated: (c) {
                        _pdfController = c;
                      },
                      onRender: (pages) {
                        try {
                          // Sync document metadata with our controller.
                          ctrl.setTotalPages(pages ?? 0, context: context);
                        } catch (_) {
                          showAppSnackBar(
                            context,
                            'Could not render PDF pages.',
                          );
                        }
                      },
                      onPageChanged: (page, _) {
                        try {
                          ctrl.setCurrentPage(page ?? 0, context: context);
                        } catch (_) {
                          // Non-critical update.
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
                  ),

                  // ── Draggable Page Indicator ──────────────────────────────────
                  if (ctrl.totalPages > 0)
                    Positioned(
                      top: _indicatorTop,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _showJumpToPageDialog(context, ctrl),
                        onVerticalDragUpdate: (details) {
                          const pillHeight = 36.0;
                          final newTop = (_indicatorTop + details.delta.dy)
                              .clamp(0.0, bodyHeight - pillHeight);
                          setState(() => _indicatorTop = newTop);
                          // Map drag position → page number
                          // top=0 → page 1, bottom → last page
                          final ratio = newTop / (bodyHeight - pillHeight);
                          final targetPage = (ratio * ctrl.totalPages - 1)
                              .round();
                          _pdfController?.setPage(targetPage);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.pageIndicatorPaddingH,
                            vertical: AppDimensions.pageIndicatorPaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: ctrl.isNightMode
                                ? AppColors.pageIndicatorBackground
                                : AppColors.primaryText,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.pageIndicatorBorderRadius,
                            ),
                            border: Border.all(
                              color: AppColors.dividerColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.scaffoldBackground.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Sliding Search/Copy Bar ──────────────────────────────────
                  // Note: flutter_pdfview renders as images; this bar allows
                  // the user to type and copy text independently.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    bottom: ctrl.isSearchBarVisible ? 0 : -80,
                    left: 0,
                    right: 0,
                    child: _CopyTextBar(isNightMode: ctrl.isNightMode),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy text bar widget
// ─────────────────────────────────────────────────────────────────────────────

/// A bottom bar widget for typing and copying text.
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
    // Styling adapts to night mode.
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
            // Button to copy typed content to system clipboard.
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
            // Button to close/clear the bar.
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
