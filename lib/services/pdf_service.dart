import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
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

  /// Convert PDF pages to images using printing package (more robust)
  static Future<List<File>> pdfToImages(String pdfPath) async {
    final dir = await FileStorageService.getCCPdfDirectory();
    final bytes = await File(pdfPath).readAsBytes();
    final List<File> imageFiles = [];
    final baseName = p.basenameWithoutExtension(pdfPath);

    int i = 1;
    await for (final page in Printing.raster(bytes, dpi: 300)) {
      final pngBytes = await page.toPng();
      final file = File(p.join(dir.path, '${baseName}_page_$i.png'));
      await file.writeAsBytes(pngBytes);
      imageFiles.add(file);
      i++;
    }

    return imageFiles;
  }

  /// Render PDF pages as image bytes for preview (using printing package)
  static Future<List<Uint8List>> renderPdfPages(String pdfPath) async {
    final bytes = await File(pdfPath).readAsBytes();
    final List<Uint8List> pages = [];

    await for (final page in Printing.raster(bytes, dpi: 150)) {
      final pngBytes = await page.toPng();
      pages.add(Uint8List.fromList(pngBytes));
    }

    return pages;
  }
}
