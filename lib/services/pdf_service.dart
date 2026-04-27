import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'file_storage_service.dart';

class PdfService {
  /// Convert multiple images into a single multi-page PDF
  static Future<File> imagesToPdf(List<String> imagePaths, String fileName) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final image = pw.MemoryImage(File(path).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final dir = await FileStorageService.getCCPdfDirectory();
    final file = File(p.join(dir.path, '$fileName.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Convert each image into a separate single-page PDF
  static Future<List<File>> imagesToSeparatePdfs(List<String> imagePaths, String baseName) async {
    final dir = await FileStorageService.getCCPdfDirectory();
    final List<File> files = [];

    for (int i = 0; i < imagePaths.length; i++) {
      final pdf = pw.Document();
      final image = pw.MemoryImage(File(imagePaths[i]).readAsBytesSync());
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final file = File(p.join(dir.path, '${baseName}_${i + 1}.pdf'));
      await file.writeAsBytes(await pdf.save());
      files.add(file);
    }

    return files;
  }

  /// Convert PDF pages to images using pdfx
  static Future<List<File>> pdfToImages(String pdfPath) async {
    final dir = await FileStorageService.getCCPdfDirectory();
    final document = await pdfx.PdfDocument.openFile(pdfPath);
    final List<File> imageFiles = [];

    final baseName = p.basenameWithoutExtension(pdfPath);

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();

      if (pageImage != null) {
        final file = File(p.join(dir.path, '${baseName}_page_$i.png'));
        await file.writeAsBytes(pageImage.bytes);
        imageFiles.add(file);
      }
    }

    await document.close();
    return imageFiles;
  }

  /// Render PDF pages as image bytes for preview (not saving to disk)
  static Future<List<Uint8List>> renderPdfPages(String pdfPath) async {
    final document = await pdfx.PdfDocument.openFile(pdfPath);
    final List<Uint8List> pages = [];

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();

      if (pageImage != null) {
        pages.add(Uint8List.fromList(pageImage.bytes));
      }
    }

    await document.close();
    return pages;
  }
}
