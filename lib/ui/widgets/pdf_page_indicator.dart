import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';

class PdfPageIndicator extends StatelessWidget {
  static const double height = 36.0;

  final double top;
  final double bodyHeight;
  final int currentPage;
  final int totalPages;
  final bool isNightMode;
  final VoidCallback onTap;
  final ValueChanged<double> onTopChanged;
  final ValueChanged<int> onPageSelected;

  const PdfPageIndicator({
    super.key,
    required this.top,
    required this.bodyHeight,
    required this.currentPage,
    required this.totalPages,
    required this.isNightMode,
    required this.onTap,
    required this.onTopChanged,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: 12,
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragUpdate: (details) {
          final maxTop = (bodyHeight - height).clamp(0.0, double.infinity);
          final newTop = (top + details.delta.dy).clamp(0.0, maxTop);
          onTopChanged(newTop);

          final ratio = maxTop == 0 ? 0.0 : newTop / maxTop;
          final targetPage = (ratio * (totalPages - 1)).round() + 1;
          onPageSelected(targetPage);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageIndicatorPaddingH,
            vertical: AppDimensions.pageIndicatorPaddingV,
          ),
          decoration: BoxDecoration(
            color: isNightMode
                ? AppColors.pageIndicatorBackground
                : AppColors.primaryText,
            borderRadius: BorderRadius.circular(
              AppDimensions.pageIndicatorBorderRadius,
            ),
            border: Border.all(color: AppColors.dividerColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.scaffoldBackground.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$currentPage / $totalPages',
            style: AppTextStyles.pageIndicator.copyWith(
              color: isNightMode
                  ? AppColors.primaryText
                  : AppColors.cardBackground,
            ),
          ),
        ),
      ),
    );
  }
}
