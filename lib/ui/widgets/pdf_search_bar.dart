import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:pdf_reader/core/app_theme.dart';

class PdfSearchBar extends StatefulWidget {
  final bool isNightMode;
  final pdfrx.PdfTextSearcher textSearcher;
  final VoidCallback onClose;

  const PdfSearchBar({
    super.key,
    required this.isNightMode,
    required this.textSearcher,
    required this.onClose,
  });

  @override
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      widget.textSearcher.resetTextSearch();
    } else {
      widget.textSearcher.startTextSearch(query, caseInsensitive: true);
    }
  }

  Future<void> _goToPreviousMatch() async {
    await widget.textSearcher.goToPrevMatch();
    if (mounted) setState(() {});
  }

  Future<void> _goToNextMatch() async {
    await widget.textSearcher.goToNextMatch();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final barBg = widget.isNightMode
        ? AppColors.cardBackground
        : AppColors.lightBackground;
    final fieldBg = widget.isNightMode
        ? AppColors.searchBarBackground
        : AppColors.lightSearchBarBackground;
    final textColor = widget.isNightMode
        ? AppColors.primaryText
        : AppColors.cardBackground;

    final matches = widget.textSearcher.matches;
    final currentIndex = widget.textSearcher.currentIndex;

    return Container(
      color: barBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
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
                  style: AppTextStyles.searchInput.copyWith(color: textColor),
                  cursorColor: AppColors.pdfIconColor,
                  decoration: const InputDecoration(
                    hintText: 'Search text in PDF...',
                    hintStyle: AppTextStyles.searchHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchChanged,
                ),
              ),
            ),
            if (matches.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${(currentIndex ?? -1) + 1}/${matches.length}',
                style: TextStyle(
                  color: widget.isNightMode
                      ? AppColors.primaryText
                      : AppColors.cardBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Previous match',
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.accentText,
                  size: 24,
                ),
                onPressed: _goToPreviousMatch,
              ),
              IconButton(
                tooltip: 'Next match',
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentText,
                  size: 24,
                ),
                onPressed: _goToNextMatch,
              ),
            ] else if (_controller.text.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                'No results',
                style: TextStyle(
                  color: widget.isNightMode
                      ? AppColors.secondaryText
                      : AppColors.cardBackground.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
            IconButton(
              tooltip: 'Clear & Close',
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.secondaryText,
                size: 20,
              ),
              onPressed: () {
                _controller.clear();
                widget.textSearcher.resetTextSearch();
                widget.onClose();
              },
            ),
          ],
        ),
      ),
    );
  }
}
