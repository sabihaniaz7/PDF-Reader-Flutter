import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/screens/home_screen.dart';
import 'package:pdf_reader/ui/screens/pdf_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Main entry point of the application.
///
/// This file initializes the [PdfLibraryController] provider and sets up the root [MyApp] widget.
/// It also handles deep linking via [receive_sharing_intent] to allow the app to be opened
/// when a PDF file is shared from another application.
void main() {
  runApp(
    // Global provider for managing the PDF library state across the entire app.
    ChangeNotifierProvider(
      create: (_) => PdfLibraryController(),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the PDF Reader application.
///
/// This widget manages the app's overall theme, navigation, and initial setup
/// for handling external PDF sharing intents.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Subscription for listening to media sharing intents while the app is running.
  StreamSubscription? _intentSub;
  // Key to access the Navigator state from outside the widget tree (for intent handling).
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Start listening for incoming PDF file sharing intents.
    _handleIncomingPdfs();
  }

  /// Sets up listeners for both cold start and background sharing intents.
  void _handleIncomingPdfs() {
    try {
      // Handle PDF opened via sharing intent while the app is already running in background.
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> files) {
          _openSharedPdf(files);
        },
        onError: (e) {
          debugPrint('[main] intent stream error: $e');
        },
      );

      // Handle PDF opened via sharing intent when the app was completely closed (cold start).
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> files) {
            _openSharedPdf(files);
            // Reset the initial media to prevent re-opening on hot restart.
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((e) {
            debugPrint('[main] getInitialMedia error: $e');
          });
    } catch (e) {
      debugPrint('[main] _handleIncomingPdfs error: $e');
    }
  }

  /// Filters out PDF files from shared media and navigates to the viewer screen.
  void _openSharedPdf(List<SharedMediaFile> files) {
    try {
      // Ensure we only process .pdf files.
      final pdfs = files.where((f) => f.path.toLowerCase().endsWith('.pdf'));
      if (pdfs.isEmpty) return;

      final file = pdfs.first;
      final name = file.path.split('/').last;

      // Use a post-frame callback to ensure navigation happens after the frame is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(pdfPath: file.path, pdfName: name),
          ),
        );
      });
    } catch (e) {
      debugPrint('[main] _openSharedPdf error: $e');
    }
  }

  @override
  void dispose() {
    // Clean up the intent stream subscription to prevent memory leaks.
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "PDF Reader",
      // Application theme configuration.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark, // Default to dark theme for the main UI.
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // Entry screen of the application.
      home: HomeScreen(),
    );
  }
}
