import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
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
              IconButton(
                icon: Icon(_isSearching ? Icons.cancel : Icons.search_outlined),
                iconSize: 30,
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
