import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import "package:path/path.dart" as p;

import '../view_models/pdf_combiner_view_model.dart';

class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  final PdfToImagesViewModel _viewModel = PdfToImagesViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Images'),
        actions: [
          IconButton(onPressed: _pickFiles, icon: const Icon(Icons.add), tooltip: "New PDF"),
          IconButton(onPressed: _restart, icon: const Icon(Icons.restart_alt), tooltip: "Restart"),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_viewModel.outputFiles.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _viewModel.outputFiles.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Image.file(
                        File(_viewModel.outputFiles[index]),
                        width: 50,
                        height: 50,
                      ),
                      title: Text(
                        p.basename(_viewModel.outputFiles[index]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onTap: () => _openImageFile(index), // Open file on tap
                    );
                  },
                ),
              ),
            ElevatedButton(
              onPressed: _viewModel.selectedFile != null ? _convertToImages : null,
              child: const Text('Convert PDF to Images'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    await _viewModel.pickFile();
    setState(() {});
  }

  void _restart() {
    _viewModel.restart();
    setState(() {});
  }

  Future<void> _convertToImages() async {
    try {
      await _viewModel.convertPdfToImages();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF successfully converted to images!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _openImageFile(int index) async {
    if (index < _viewModel.outputFiles.length) {
      final result = await OpenFile.open(_viewModel.outputFiles[index]);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file. Error: ${result.message}')),
        );
      }
    }
  }
}
