// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
//
// class PDFViewerScreen extends StatefulWidget {
//   const PDFViewerScreen({super.key});
//
//   @override
//   State<PDFViewerScreen> createState() => _PDFViewerScreenState();
// }
//
// class _PDFViewerScreenState extends State<PDFViewerScreen> {
//   final PdfViewerController controllerVertical = PdfViewerController();
//   final PdfViewerController controllerHorizontal = PdfViewerController();
//   bool isSyncing = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PDF Viewer'),
//       ),
//       body: Column(
//         children: [
//           // Main Vertical PDF Viewer
//           Expanded(
//             flex: 10,
//             child: SfPdfViewer.asset(
//               'assets/book.pdf',
//               controller: controllerVertical,
//               pageLayoutMode: PdfPageLayoutMode.single,
//               onPageChanged: (details) {
//                 if (!isSyncing) {
//                   isSyncing = true;
//                   controllerHorizontal.jumpToPage(details.newPageNumber);
//                   isSyncing = false;
//                 }
//               },
//               canShowScrollHead: false,
//               interactionMode: PdfInteractionMode.selection,
//               scrollDirection: PdfScrollDirection.vertical,
//             ),
//           ),
//
//           // Horizontal Thumbnail Viewer
//           Expanded(
//             flex: 3,
//             child: SfPdfViewer.asset(
//               'assets/book.pdf',
//               controller: controllerHorizontal,
//               pageLayoutMode: PdfPageLayoutMode.continuous,
//               scrollDirection: PdfScrollDirection.horizontal,
//               enableDoubleTapZooming: false,
//               enableDocumentLinkAnnotation: false,
//               enableHyperlinkNavigation: false,
//               enableTextSelection: false,
//               canShowScrollHead: false,
//               canShowPaginationDialog: false,
//               canShowScrollStatus: true,
//               onTap: (details) {
//                 if (!isSyncing) {
//                   isSyncing = true;
//                   controllerVertical.jumpToPage(details.pageNumber);
//
//                   isSyncing = false;
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: const PDFViewerScreen(),
//   ));
// }
