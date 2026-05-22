import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/widgets/pdf_document_view.dart';
import 'package:pdf_reader/ui/widgets/pdf_jump_to_page_dialog.dart';
import 'package:pdf_reader/ui/widgets/pdf_page_indicator.dart';
import 'package:pdf_reader/ui/widgets/pdf_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// A dedicated screen for viewing PDF documents.
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
  late final pdfrx.PdfViewerController _pdfController;
  pdfrx.PdfTextSearcher? _textSearcher;
  double _indicatorTop = 12.0;

  @override
  void initState() {
    super.initState();
    _pdfController = pdfrx.PdfViewerController();
  }

  @override
  void dispose() {
    _textSearcher?.removeListener(_onSearchUpdated);
    _textSearcher?.dispose();
    super.dispose();
  }

  void _onSearchUpdated() {
    if (mounted) setState(() {});
  }

  void _ensureTextSearcher() {
    if (_textSearcher != null) return;

    _textSearcher = pdfrx.PdfTextSearcher(_pdfController)
      ..addListener(_onSearchUpdated);

    if (mounted) setState(() {});
  }

  Future<void> _handlePdfLinkTap(pdfrx.PdfLink link) async {
    final url = link.url;
    if (url != null) {
      try {
        final opened = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          showAppSnackBar(context, 'Could not open link.');
        }
      } catch (_) {
        if (mounted) {
          showAppSnackBar(context, 'Could not open link.');
        }
      }
      return;
    }

    final destination = link.dest;
    if (destination != null) {
      await _pdfController.goToDest(destination);
    }
  }

  void _showJumpToPageDialog(PdfViewerController controller) {
    showPdfJumpToPageDialog(
      context: context,
      controller: controller,
      onPageSelected: (page) => _pdfController.goToPage(pageNumber: page),
    );
  }

  void _toggleSearchBar(PdfViewerController controller) {
    if (_textSearcher == null) {
      showAppSnackBar(context, 'PDF is still loading.');
      return;
    }

    controller.toggleSearchBar();
    if (!controller.isSearchBarVisible) {
      _textSearcher?.resetTextSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerController>(
      builder: (context, controller, _) {
        final isNight = controller.isNightMode;
        final iconColor = isNight
            ? AppColors.primaryText
            : AppColors.cardBackground;
        final backgroundColor = isNight
            ? AppColors.scaffoldBackground
            : AppColors.lightBackground;

        return SafeArea(
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: _buildAppBar(controller, isNight, iconColor),
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    PdfDocumentView(
                      pdfPath: widget.pdfPath,
                      isNightMode: isNight,
                      controller: _pdfController,
                      textSearcher: _textSearcher,
                      onLinkTap: _handlePdfLinkTap,
                      onViewerReady: (document, pdfController) {
                        _ensureTextSearcher();
                        controller.setTotalPages(
                          pdfController.pageCount,
                          context: context,
                        );
                        controller.setCurrentPage(
                          (pdfController.pageNumber ?? 1) - 1,
                          context: context,
                        );
                      },
                      onPageChanged: (pageNumber) {
                        if (pageNumber == null) return;
                        controller.setCurrentPage(
                          pageNumber - 1,
                          context: context,
                        );
                      },
                    ),
                    if (controller.totalPages > 0)
                      PdfPageIndicator(
                        top: _indicatorTop,
                        bodyHeight: constraints.maxHeight,
                        currentPage: controller.currentPage,
                        totalPages: controller.totalPages,
                        isNightMode: isNight,
                        onTap: () => _showJumpToPageDialog(controller),
                        onTopChanged: (top) {
                          setState(() => _indicatorTop = top);
                        },
                        onPageSelected: (page) {
                          _pdfController.goToPage(pageNumber: page);
                        },
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      bottom: controller.isSearchBarVisible ? 0 : -80,
                      left: 0,
                      right: 0,
                      child: _textSearcher == null
                          ? const SizedBox.shrink()
                          : PdfSearchBar(
                              isNightMode: isNight,
                              textSearcher: _textSearcher!,
                              onClose: controller.hideSearchBar,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    PdfViewerController controller,
    bool isNight,
    Color iconColor,
  ) {
    return AppBar(
      backgroundColor: isNight
          ? AppColors.scaffoldBackground
          : AppColors.lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      title: Text(
        widget.pdfName,
        style: AppTextStyles.appBarTitle.copyWith(
          fontSize: AppTextStyles.appBarTitleSmall.fontSize,
          color: iconColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          tooltip: isNight ? 'Light Mode' : 'Night Mode',
          icon: Icon(
            isNight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: isNight ? AppColors.nightModeOff : AppColors.nightModeOn,
          ),
          onPressed: controller.toggleNightMode,
        ),
        IconButton(
          tooltip: 'Search Text',
          icon: Icon(
            controller.isSearchBarVisible
                ? Icons.search_off_rounded
                : Icons.search_rounded,
            color: iconColor,
          ),
          onPressed: () => _toggleSearchBar(controller),
        ),
        IconButton(
          tooltip: 'Jump to page',
          icon: const Icon(Icons.swap_vert),
          color: iconColor,
          onPressed: () => _showJumpToPageDialog(controller),
        ),
      ],
    );
  }
}
