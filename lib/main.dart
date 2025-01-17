import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p; // Fayl yo‘llarini boshqarish uchun
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'PDF Combiner Example',
    debugShowCheckedModeBanner: false,
    home: PdfToImagesScreen(
      pdfUrl:
      'https://www.sharedfilespro.com/shared-files/38/?10-page-sample.pdf',
    ),
  );
}

class PdfToImagesScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfToImagesScreen({super.key, required this.pdfUrl});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  late final PdfToImagesViewModel _viewModel;
  PdfController? _pdfController; // PdfX PdfController (nullable)
  final ScrollController _thumbScrollController = ScrollController();
  List<GlobalKey> _thumbKeys = [];

  @override
  void initState() {
    super.initState();
    _viewModel = PdfToImagesViewModel(pdfUrl: widget.pdfUrl);
    _loadAndConvertPdf();
  }

  Future<void> _loadAndConvertPdf() async {
    try {
      await _viewModel.fetchStaticPdf();
      await _viewModel.convertPdfToImages();
      _pdfController = PdfController(
        document: PdfDocument.openFile(_viewModel.selectedFile!),
      );
      _thumbKeys =
          List.generate(_viewModel.imageBytes.length, (_) => GlobalKey());
      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  /// Bu metod tanlangan thumbnail elementini horizontal ListView konteyneriga nisbatan markazlash uchun offset hisoblaydi.
  void _scrollToThumbnail(int pageNumber) {
    if (pageNumber - 1 < _thumbKeys.length) {
      final keyContext = _thumbKeys[pageNumber - 1].currentContext;
      if (keyContext != null) {
        // Thumbnail elementining global offsetini aniqlaymiz.
        final RenderBox thumbBox = keyContext.findRenderObject() as RenderBox;
        final thumbGlobalPosition = thumbBox.localToGlobal(Offset.zero);

        // Horizontal ListView konteynerining global offsetini aniqlash uchun:
        final RenderBox listBox = _thumbScrollController.position.context.storageContext.findRenderObject() as RenderBox;
        final listGlobalPosition = listBox.localToGlobal(Offset.zero);

        // Kerakli offset: thumbnailni ListView markaziga joylashtirish uchun:
        final double thumbCenter = thumbGlobalPosition.dx + thumbBox.size.width / 2;
        final double listCenter = listGlobalPosition.dx + listBox.size.width / 2;
        final double offsetDifference = thumbCenter - listCenter;

        // Hozirgi scroll offsetga bu farqni qo'shamiz:
        final double targetOffset = (_thumbScrollController.offset + offsetDifference)
            .clamp(0.0, _thumbScrollController.position.maxScrollExtent);

        _thumbScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _thumbScrollController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pdfController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_viewModel.imageBytes.isNotEmpty &&
        _thumbKeys.length != _viewModel.imageBytes.length) {
      _thumbKeys =
          List.generate(_viewModel.imageBytes.length, (_) => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Images (PDFX Viewer)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PDF faylini PdfView orqali ko'rsatish:
            Expanded(
              flex: 10,
              child: PdfView(
                controller: _pdfController!,
                onPageChanged: (page) {
                  setState(() {});
                  _scrollToThumbnail(page);
                },
              ),
            ),
            // Thumbnail rasmlar horizontal ListView orqali:
            if (_viewModel.imageBytes.isNotEmpty)
              Expanded(
                flex: 3,
                child: ListView.builder(
                  controller: _thumbScrollController,
                  itemCount: _viewModel.imageBytes.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => GestureDetector(
                    key: _thumbKeys[index],
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      decoration: BoxDecoration(
                        border: _pdfController!.page == index + 1
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
                      ),
                      child: Image.memory(_viewModel.imageBytes[index]),
                    ),
                    onTap: () {
                      _pdfController!.animateToPage(
                        index + 1,
                        duration: const Duration(microseconds: 200),
                        curve: Curves.linear,
                      );
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
  final String pdfUrl; // PDF URL manzili
  String? selectedFile; // Diskda cache qilingan PDF faylining yo'li
  final List<Uint8List> imageBytes = []; // In-memory saqlash: sahifa rasmlari baytlari

  PdfToImagesViewModel({required this.pdfUrl});

  /// PDF-ni diskdagi temporary papkaga cache qiladi.
  /// Fayl nomi URL oxiridagi segment yoki query qismidan olinadi.
  Future<void> fetchStaticPdf() async {
    final tempDir = await getTemporaryDirectory();
    final uri = Uri.parse(pdfUrl);

    // Fayl nomini aniqlash: agar query mavjud bo'lsa, uni; aks holda oxirgi path segmentni olamiz.
    String fileName = '';
    if (uri.query.isNotEmpty) {
      fileName = uri.query;
    } else if (uri.pathSegments.isNotEmpty) {
      fileName = uri.pathSegments.last;
    }

    if (fileName.trim().isEmpty) {
      fileName = 'downloaded.pdf';
    }
    if (p.extension(fileName).isEmpty) {
      fileName = '$fileName.pdf';
    }

    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      selectedFile = filePath;
      debugPrint('PDF file already exists: $selectedFile');
      return;
    }
    final response = await http.get(Uri.parse(pdfUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      selectedFile = filePath;
      debugPrint('PDF file downloaded and saved at: $selectedFile');
    } else {
      throw Exception('Failed to download PDF.');
    }
  }

  /// Diskdagi PDF faylidan sahifalarni render qilib, ularni in-memory rasmlarga aylantiradi.
  Future<void> convertPdfToImages() async {
    if (selectedFile == null) throw Exception('No PDF selected.');
    final pdfDoc = await PdfDocument.openFile(selectedFile!);
    for (var i = 1; i <= pdfDoc.pagesCount; i++) {
      final page = await pdfDoc.getPage(i);
      final image = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
      );
      imageBytes.add(image!.bytes);
      await page.close();
    }
    await pdfDoc.close();
  }
}
