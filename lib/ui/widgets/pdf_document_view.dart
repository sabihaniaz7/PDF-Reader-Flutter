import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:pdf_reader/core/app_theme.dart';

class PdfDocumentView extends StatelessWidget {
  final String pdfPath;
  final bool isNightMode;
  final pdfrx.PdfViewerController controller;
  final pdfrx.PdfTextSearcher? textSearcher;
  final void Function(pdfrx.PdfLink link) onLinkTap;
  final void Function(
    pdfrx.PdfDocument document,
    pdfrx.PdfViewerController controller,
  )
  onViewerReady;
  final void Function(int? pageNumber) onPageChanged;

  const PdfDocumentView({
    super.key,
    required this.pdfPath,
    required this.isNightMode,
    required this.controller,
    required this.textSearcher,
    required this.onLinkTap,
    required this.onViewerReady,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isNightMode ? AppColors.scaffoldBackground : AppColors.primaryText,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white,
          isNightMode ? BlendMode.difference : BlendMode.dst,
        ),
        child: pdfrx.PdfViewer.file(
          pdfPath,
          controller: controller,
          params: pdfrx.PdfViewerParams(
            linkHandlerParams: pdfrx.PdfLinkHandlerParams(onLinkTap: onLinkTap),
            textSelectionParams: const pdfrx.PdfTextSelectionParams(
              enabled: true,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            pagePaintCallbacks: [
              if (textSearcher != null)
                textSearcher!.pageTextMatchPaintCallback,
            ],
            onViewerReady: onViewerReady,
            onPageChanged: onPageChanged,
          ),
        ),
      ),
    );
  }
}
