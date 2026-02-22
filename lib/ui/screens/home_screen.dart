import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/sort_option.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/screens/pdf_viewer_screen.dart';
import 'package:pdf_reader/widgets/pdf_list_tab.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:provider/provider.dart';

/// The primary entry screen of the application.
///
/// It features a three-tab layout (On Device, Recent, Favorites) allowing users
/// to browse their PDF library. It also provides global search, sorting,
/// and manual refresh functionality.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Controls the visibility of the search bar in the [AppBar].
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 3 tabs: All, Recent, Favorites.
    _tabController = TabController(length: 3, vsync: this);

    // Schedule initial library scan after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // init() checks local storage first and only scans physical storage
      // if it's the very first time the app is launched or data was cleared.
      context.read<PdfLibraryController>().init(context: context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Handles opening a PDF file by marking it as 'opened' and navigating to the viewer.
  void _openPdf(BuildContext context, PdfFileModel file) {
    // Record the open event for the 'Recent' tab functionality.
    context.read<PdfLibraryController>().markOpened(file);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PdfViewerScreen(pdfPath: file.path, pdfName: file.name),
      ),
    );
  }

  /// Displays the modal bottom sheet for selecting a list sorting preference.
  void _showSortSheet(BuildContext context, PdfLibraryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Use custom modal styling from AppThemes.
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.modalBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.modalTopRadius),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual drag handle at the top of the modal.
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Sort By", style: AppTextStyles.modalTitle),
                  ),
                ),
                Divider(color: AppColors.dividerColor, height: 1),
                // Build a radio-style list from the SortOption enum values.
                ...SortOption.values.map((option) {
                  final isSelected = controller.sortOption == option;
                  return InkWell(
                    onTap: () {
                      controller.setSortOption(option);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? AppColors.pdfIconColor
                                : AppColors.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            option.label,
                            style: AppTextStyles.modalActionLabel.copyWith(
                              color: isSelected
                                  ? AppColors.primaryText
                                  : AppColors.accentText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfLibraryController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.scaffoldBackground,
            elevation: 0,
            // Toggle between app title and search input.
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: AppColors.primaryText),
                    cursorColor: AppColors.pdfIconColor,
                    decoration: const InputDecoration(
                      hintText: "Search PDFs",
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      border: InputBorder.none,
                    ),
                    onChanged: controller.search,
                  )
                : const Text("PDF Reader", style: AppTextStyles.appBarTitle),
            actions: [
              // Search toggle button (starts/stops search mode).
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                ),
                iconSize: 26,
                color: AppColors.primaryText,
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      controller.search(""); // Reset list to full library.
                    }
                  });
                },
              ),
              // Sort preference button.
              IconButton(
                icon: const Icon(
                  Icons.sort_rounded,
                  color: AppColors.primaryText,
                  size: 26,
                ),
                onPressed: () => _showSortSheet(context, controller),
              ),
              // Manual Refresh button to trigger a device re-scan.
              IconButton(
                tooltip: 'Refresh',
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryText,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primaryText,
                        size: 26,
                      ),
                onPressed: () => controller.refreshPdfs(context: context),
              ),
            ],
            // Tab bar for switching between library segments.
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.tabIndicator,
              indicatorWeight: 2.5,
              labelColor: AppColors.tabLabelActive,
              unselectedLabelColor: AppColors.tabLabelInactive,
              labelStyle: AppTextStyles.tabLabel,
              unselectedLabelStyle: AppTextStyles.tabLabel,
              tabs: const [
                Tab(text: 'On Device'),
                Tab(text: 'Recent'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),
          // Conditional body: show loader during first launch scan, else show tabs.
          body: controller.isLoading && controller.allFiles.isEmpty
              ? const _FirstLaunchLoader()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Full Library (All discovered PDFs).
                    PdfListTab(
                      files: controller.allFiles,
                      isLoading: controller.isLoading,
                      emptyMessage: "No PDFs found on device",
                      onFileTap: (file) => _openPdf(context, file),
                      onToggleFavorite: controller.toggleFavorite,
                      onDelete: controller.deleteFile,
                      onShare: controller.shareFile,
                    ),
                    // Tab 2: Recents (Files sorted by last opened time).
                    PdfListTab(
                      files: controller.recentFiles,
                      isLoading: controller.isLoading,
                      emptyMessage: "No recently opened PDFs",
                      onFileTap: (file) => _openPdf(context, file),
                      onToggleFavorite: controller.toggleFavorite,
                      onDelete: controller.deleteFile,
                      onShare: controller.shareFile,
                    ),
                    // Tab 3: Favorites (User-starred files).
                    PdfListTab(
                      files: controller.favouriteFiles,
                      isLoading: controller.isLoading,
                      emptyMessage: "No Starred PDFs yet",
                      onFileTap: (file) => _openPdf(context, file),
                      onToggleFavorite: controller.toggleFavorite,
                      onDelete: controller.deleteFile,
                      onShare: controller.shareFile,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// A specific loading view shown only during the initial device storage scan.
class _FirstLaunchLoader extends StatelessWidget {
  const _FirstLaunchLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.pdfIconColor),
          SizedBox(height: 20),
          Text("Scanning for PDFs...", style: AppTextStyles.emptyStateText),
          SizedBox(height: 6),
          Text(
            "This may take a few seconds on first launch",
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
