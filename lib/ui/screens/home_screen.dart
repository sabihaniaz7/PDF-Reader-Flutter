import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/screens/pdf_viewer_screen.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
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
                      hintText: "Search PDFs...",
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
                    _filteredFiles = _pdfFiles;
                  });
                },
              ),
            ],
          ),
          body: _filteredFiles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredFiles.length,
                  itemBuilder: (context, index) {
                    String filePath = _filteredFiles[index];
                    String fileName = path.basename(filePath);
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 30,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfViewerScreen(
                                pdfName: fileName,
                                pdfPath: filePath,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
