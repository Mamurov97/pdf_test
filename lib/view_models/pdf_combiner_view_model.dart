import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfToImagesViewModel {
  String? selectedFile;
  List<String> outputFiles = [];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      selectedFile = result.files.single.path;
    }
  }

  void restart() {
    selectedFile = null;
    outputFiles = [];
  }

  Future<void> convertPdfToImages() async {
    if (selectedFile == null) {
      throw Exception('No PDF file selected.');
    }

    final directory = await _getOutputDirectory();
    final pdfDocument = await PdfDocument.openFile(selectedFile!);

    for (int i = 1; i <= pdfDocument.pagesCount; i++) {
      final page = await pdfDocument.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
      );

      final outputFilePath = '${directory?.path}/page_$i.png';
      File(outputFilePath).writeAsBytesSync(pageImage!.bytes);
      outputFiles.add(outputFilePath);

      await page.close();
    }

    await pdfDocument.close();
  }

  Future<Directory?> _getOutputDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getDownloadsDirectory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
