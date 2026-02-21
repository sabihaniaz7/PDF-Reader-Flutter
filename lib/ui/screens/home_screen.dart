import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/data/models/sort_option.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/screens/pdf_viewer_screen.dart';
import 'package:pdf_reader/widgets/pdf_list_tab.dart';
import 'package:pdf_reader/data/models/pdf_file_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PdfLibraryController>().loadPdfs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  //to open pdfs
  void _openPdf(BuildContext context, PdfFileModel file) {
    context.read<PdfLibraryController>().markOpened(file);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PdfViewerScreen(pdfPath: file.path, pdfName: file.name),
      ),
    );
  }

  void _showSortSheet(BuildContext context, PdfLibraryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                // Handle
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
                    child: Text("Sort by", style: AppTextStyles.modalTitle),
                  ),
                ),
                Divider(color: AppColors.dividerColor, height: 1),
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
              //search icon
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                ),
                iconSize: 30,
                color: AppColors.primaryText,
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      controller.search("");
                    }
                  });
                },
              ),
              // Sort Button
              IconButton(
                icon: const Icon(
                  Icons.sort_rounded,
                  color: AppColors.primaryText,
                  size: 26,
                ),
                onPressed: () => _showSortSheet(context, controller),
              ),
            ],
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
          body: TabBarView(
            controller: _tabController,
            children: [
              // On Device Tab
              PdfListTab(
                files: controller.allFiles,
                isLoading: controller.isLoading,
                emptyMessage: "No PDFs found on device",
                onFileTap: (file) => _openPdf(context, file),
                onToggleFavorite: controller.toggleFavorite,
                onDelete: controller.deleteFile,
                onShare: controller.shareFile,
              ),
              // Recent Tab
              PdfListTab(
                files: controller.recentFiles,
                isLoading: controller.isLoading,
                emptyMessage: "No recently opened PDFs",
                onFileTap: (file) => _openPdf(context, file),
                onToggleFavorite: controller.toggleFavorite,
                onDelete: controller.deleteFile,
                onShare: controller.shareFile,
              ),
              // Favorites Tab
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
