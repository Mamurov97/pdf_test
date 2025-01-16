import 'package:flutter/material.dart';
import 'package:pdf_test/views/pdf_combiner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Combiner Example',
      debugShowCheckedModeBanner: false,
      home: const PdfToImagesScreen(),
    );
  }
}
