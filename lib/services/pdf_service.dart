import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:image/image.dart' as img;
import 'file_storage_service.dart';

class PdfService {
  static const String watermarkText = 'CCPdf';

  /// Add a small watermark at the bottom of a PDF page
  static pw.Widget _buildWatermark() {
    return pw.Container(
      alignment: pw.Alignment.bottomRight,
      padding: const pw.EdgeInsets.only(bottom: 10, right: 20),
      child: pw.Text(
        watermarkText,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey400,
        ),
      ),
    );
  }

  /// Convert multiple images into a single multi-page PDF with watermark
  static Future<File> imagesToPdf(List<String> imagePaths, String fileName) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final image = pw.MemoryImage(File(path).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: _buildWatermark(),
                ),
              ],
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

  /// Convert each image into a separate single-page PDF with watermark
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
            return pw.Stack(
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: _buildWatermark(),
                ),
              ],
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

  /// Convert PDF pages to images using pdfrx and add watermark
  static Future<List<File>> pdfToImages(String pdfPath) async {
    final dir = await FileStorageService.getCCPdfDirectory();
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    final List<File> imageFiles = [];
    final baseName = p.basenameWithoutExtension(pdfPath);

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        fullWidth: page.width * 2,
        fullHeight: page.height * 2,
        backgroundColor: '#ffffff',
      );
      
      if (pageImage != null) {
        final Uint8List bytes = pageImage.pixels;
        
        final imgObj = img.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: bytes,
          numChannels: 4,
          format: img.Format.uint8,
        );

        img.drawString(
          imgObj,
          watermarkText,
          font: img.arial24,
          x: imgObj.width - 100,
          y: imgObj.height - 40,
          color: img.ColorRgb8(150, 150, 150),
        );

        final pngBytes = img.encodePng(imgObj);
        final file = File(p.join(dir.path, '${baseName}_page_$i.png'));
        await file.writeAsBytes(pngBytes);
        imageFiles.add(file);
      }
    }

    await document.close();
    return imageFiles;
  }

  /// Render PDF pages as image bytes for preview (using pdfrx)
  static Future<List<Uint8List>> renderPdfPages(String pdfPath) async {
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    final List<Uint8List> pages = [];

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        fullWidth: page.width,
        fullHeight: page.height,
        backgroundColor: '#ffffff',
      );

      if (pageImage != null) {
        final Uint8List bytes = pageImage.pixels;
        final imgObj = img.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: bytes,
          numChannels: 4,
          format: img.Format.uint8,
        );
        
        final pngBytes = img.encodePng(imgObj);
        pages.add(Uint8List.fromList(pngBytes));
      }
    }

    await document.close();
    return pages;
  }
}
