import 'package:flutter/material.dart';

/// Centralized color palette for the application.
///
/// This class holds all constant color values used throughout the app
/// to ensure a consistent look and feel.
class AppColors {
  // Primary branding color (Classic Red)
  static const Color primary = Color(0xFFE53935);

  // Background colors primarily used for the dark theme.
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color modalBackground = Color(0xFF1E1E1E);
  static const Color tabBarBackground = Color(0xFF121212);
  static const Color dividerColor = Color(0xFF2C2C2C);
  static const Color bottomNavBackground = Color(0xFF1A1A1A);
  static const Color pageIndicatorBackground = Color(0xCC000000);
  static const Color searchBarBackground = Color(0xFF2A2A2A);

  // Text Colors for clear contrast.
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF9E9E9E);
  static const Color accentText = Color(0xFFBDBDBD);

  // UI Element specific colors.
  static const Color pdfIconBorder = Color(0xFFE53935);
  static const Color pdfIconBackground = Color(0xFF2A1515);
  static const Color pdfIconColor = Color(0xFFE53935);
  static const Color starActive = Color(0xFFFFC107);
  static const Color starInactive = Color(0xFF616161);
  static const Color tabIndicator = Color(0xFFE53935);
  static const Color tabLabelActive = Color(0xFFFFFFFF);
  static const Color tabLabelInactive = Color(0xFF757575);

  // Action-oriented colors.
  static const Color shareColor = Color(0xFF42A5F5);
  static const Color deleteColor = Color(0xFFEF5350);
  static const Color infoColor = Color(0xFF66BB6A);
  static const Color sortColor = Color(0xFFAB47BC);

  // Snackbar styling (Neutral tones with a red action accent).
  static const Color snackbarBackground = Color(0xFF323232);
  static const Color snackbarText = Color(0xFFFFFFFF);
  static const Color snackbarActionText = Color(0xFFE53935);

  // Night/Light mode toggle specific colors.
  static const Color nightModeOn = Color(
    0xFF90CAF9,
  ); // Sky blue specifically for the moon icon.
  static const Color nightModeOff = Color(
    0xFFFFF176,
  ); // Yellow specifically for the sun icon.
}

/// Predefined text styles to maintain typography consistency.
class AppTextStyles {
  // Typography for top navigation bars.
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  // Typography for list items and file names.
  static const TextStyle cardFileName = TextStyle(
    color: AppColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Typography for modals and dialogs.
  static const TextStyle modalTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle modalSubtitle = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 13,
  );

  static const TextStyle modalActionLabel = TextStyle(
    color: AppColors.primaryText,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Typography for tab navigation.
  static const TextStyle tabLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Typography for section headers and meta labels.
  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  // Typography for empty states and placeholders.
  static const TextStyle emptyStateText = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 15,
  );

  // Typography for the PDF viewer page indicator.
  static const TextStyle pageIndicator = TextStyle(
    color: AppColors.primaryText,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle searchHint = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 14,
  );
}

/// Standard dimensions and spacing tokens for the UI.
class AppDimensions {
  static const double cardBorderRadius = 14.0;
  static const double cardPadding = 14.0;
  static const double cardMarginH = 16.0;
  static const double cardMarginV = 6.0;
  static const double iconContainerSize = 48.0;
  static const double iconContainerBorderRadius = 10.0;
  static const double iconContainerBorderWidth = 1.5;
  static const double modalTopRadius = 20.0;
  static const double modalPaddingH = 20.0;
  static const double modalPaddingV = 16.0;
  static const double pdfIconSize = 26.0;
  static const double pageIndicatorPaddingH = 16.0;
  static const double pageIndicatorPaddingV = 8.0;
  static const double pageIndicatorBorderRadius = 20.0;
}

/// Helper function to show a standard styled Snackbar across the app.
///
/// [context] is required to find the [ScaffoldMessenger].
/// [message] is the text content to display.
/// [actionLabel] and [onAction] are optional for adding a button to the snackbar.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  // Hide current snackbar to prevent stacking if triggered multiple times quickly.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: AppColors.snackbarText, fontSize: 14),
      ),
      backgroundColor: AppColors.snackbarBackground,
      behavior:
          SnackBarBehavior.floating, // Floating rather than fixed at bottom.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.snackbarActionText,
              onPressed: onAction ?? () {},
            )
          : null,
    ),
  );
}
