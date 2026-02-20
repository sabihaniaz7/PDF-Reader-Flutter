import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_reader/core/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.pdfName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int totalPages = 0;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        title: Text(
          widget.pdfName,
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true, // Show scrollbar always
              child: PDFView(
                filePath: widget.pdfPath,
                pageFling: true,
                autoSpacing: true,
                onRender: (pages) {
                  setState(() {
                    totalPages = pages ?? 0;
                  });
                },
                onPageChanged: (page, total) {
                  setState(() {
                    currentPage =
                        (page ?? 0) + 1; // Pages are zero-indexed in PDFView
                  });
                },
              ),
            ),
          ),
          // Display current page and total pages
          Container(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  'Page $currentPage of $totalPages',
                  style: AppTextStyles.cardSubtitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
