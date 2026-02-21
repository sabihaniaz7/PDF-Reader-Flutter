import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf_reader/core/app_theme.dart';
import 'package:pdf_reader/logic/controllers/pdf_library_controller.dart';
import 'package:pdf_reader/ui/screens/home_screen.dart';
import 'package:pdf_reader/ui/screens/pdf_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PdfLibraryController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentSub;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleIncomingPdfs();
  }

  void _handleIncomingPdfs() {
    try {
      // Handle PDF opened while app is already running
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> files) {
          _openSharedPdf(files);
        },
        onError: (e) {
          debugPrint('[main] intent stream error: $e');
        },
      );

      // Handle PDF opened when app was closed (cold start)
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> files) {
            _openSharedPdf(files);
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((e) {
            debugPrint('[main] getInitialMedia error: $e');
          });
    } catch (e) {
      debugPrint('[main] _handleIncomingPdfs error: $e');
    }
  }

  void _openSharedPdf(List<SharedMediaFile> files) {
    try {
      final pdfs = files.where((f) => f.path.toLowerCase().endsWith('.pdf'));
      if (pdfs.isEmpty) return;

      final file = pdfs.first;
      final name = file.path.split('/').last;

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
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "PDF Reader",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(),
    );
  }
}
