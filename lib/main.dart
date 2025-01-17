import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdfx/pdfx.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'PDF Combiner Example',
    debugShowCheckedModeBanner: false,
    home: PdfToImagesScreen(),
  );
}

class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});
  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  final _viewModel = PdfToImagesViewModel();
  final _pdfController = PdfViewerController();
  final ScrollController _thumbScrollController = ScrollController();
  List<GlobalKey> _thumbKeys = [];

  @override
  void initState() {
    super.initState();
    _loadAndConvertPdf();
  }

  Future<void> _loadAndConvertPdf() async {
    try {
      await _viewModel.fetchStaticPdf();
      await _viewModel.convertPdfToImages();
      // Create keys for each thumbnail
      _thumbKeys = List.generate(_viewModel.outputFiles.length, (_) => GlobalKey());
      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _scrollToThumbnail(int pageNumber) {
    if (pageNumber - 1 < _thumbKeys.length) {
      final thumbContext = _thumbKeys[pageNumber - 1].currentContext;
      if (thumbContext != null) {
        Scrollable.ensureVisible(
          thumbContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _thumbKeys length matches the number of output files.
    if (_viewModel.outputFiles.isNotEmpty && _thumbKeys.length != _viewModel.outputFiles.length) {
      _thumbKeys = List.generate(_viewModel.outputFiles.length, (_) => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Images'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_viewModel.selectedFile != null)
              Expanded(
                flex: 10,
                child: SfPdfViewer.file(
                  File(_viewModel.selectedFile!),
                  controller: _pdfController,
                  onPageChanged: (details) {
                    setState(() {});
                    _scrollToThumbnail(details.newPageNumber);
                  },
                  pageLayoutMode: PdfPageLayoutMode.single,
                  canShowScrollStatus: false,
                  canShowScrollHead: false,
                  interactionMode: PdfInteractionMode.selection,
                  scrollDirection: PdfScrollDirection.vertical,
                ),
              ),
            if (_viewModel.outputFiles.isNotEmpty)
              Expanded(
                flex: 3,
                child: ListView.builder(
                  controller: _thumbScrollController,
                  itemCount: _viewModel.outputFiles.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => GestureDetector(
                    key: _thumbKeys[index],
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      decoration: BoxDecoration(
                        border: _pdfController.pageNumber == index + 1
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
                      ),
                      child: Image.file(File(_viewModel.outputFiles[index])),
                    ),
                    onTap: () {
                      _pdfController.jumpToPage(index + 1);
                      setState(() {});
                      _scrollToThumbnail(index + 1);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PdfToImagesViewModel {
  String? selectedFile;
  final List<String> outputFiles = [];
  static const String _staticPdfUrl =
      'https://www.sharedfilespro.com/shared-files/38/?10-page-sample.pdf';
  static const Duration _cacheDuration = Duration(hours: 24);

  Future<void> fetchStaticPdf() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/downloaded.pdf';
    final file = File(filePath);

    if (await file.exists()) {
      final modTime = await file.lastModified();
      if (DateTime.now().difference(modTime) < _cacheDuration) {
        selectedFile = filePath;
        return;
      }
    }

    final response = await http.get(Uri.parse(_staticPdfUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      selectedFile = filePath;
    } else {
      throw Exception('Failed to download PDF.');
    }
  }

  Future<void> convertPdfToImages() async {
    if (selectedFile == null) throw Exception('No PDF selected.');
    final dir = await _getOutputDirectory();
    if (dir == null) throw Exception('Output directory not available.');
    final pdfDoc = await PdfDocument.openFile(selectedFile!);
    for (var i = 1; i <= pdfDoc.pagesCount; i++) {
      final page = await pdfDoc.getPage(i);
      final image = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
      );
      final path = '${dir.path}/page_$i.png';
      File(path).writeAsBytesSync(image!.bytes);
      outputFiles.add(path);
      await page.close();
    }
    await pdfDoc.close();
  }

  Future<Directory?> _getOutputDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getDownloadsDirectory();
    }
    throw UnsupportedError('Unsupported platform');
  }
}
