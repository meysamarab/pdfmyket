import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'file_storage_service.dart';

enum PdfExportProfile {
  standard,
  government, // < 2 MB
  embassy,    // < 2.5 MB
  maxCompression // < 1 MB
}

class PdfService {
  static const String watermarkText = 'Created by CCScaner';


  /// Convert multiple images into a single multi-page PDF with optional compression and custom directory
  static Future<File> imagesToPdf(List<String> imagePaths, String fileName, {PdfExportProfile profile = PdfExportProfile.standard, String? customDirectory, bool addWatermark = true}) async {
    await FileStorageService.requestPermissions();
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final processedBytes = await _processImageForProfile(path, profile);
      final image = pw.MemoryImage(processedBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                if (addWatermark)
                  pw.Positioned(
                    bottom: 20,
                    right: 20,
                    child: pw.Text(
                      watermarkText,
                      style: pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    final dirPath = customDirectory ?? (await FileStorageService.getCCPdfDirectory()).path;
    final file = File(p.join(dirPath, '$fileName.pdf'));

    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Special layout for ID Card: Two images on one A4 page
  static Future<File> generateIdCardPdf(String frontPath, String backPath, String fileName, {PdfExportProfile profile = PdfExportProfile.standard, String? customDirectory, bool addWatermark = true}) async {
    await FileStorageService.requestPermissions();
    final pdf = pw.Document();

    final frontBytes = await _processImageForProfile(frontPath, profile);
    final backBytes = await _processImageForProfile(backPath, profile);

    final frontImage = pw.MemoryImage(frontBytes);
    final backImage = pw.MemoryImage(backBytes);


    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('FRONT SIDE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    height: 250,
                    width: 400,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Image(frontImage, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('BACK SIDE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    height: 250,
                    width: 400,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Image(backImage, fit: pw.BoxFit.cover),
                  ),
                ],
              ),
              if (addWatermark)
                pw.Positioned(
                  bottom: 20,
                  right: 20,
                  child: pw.Text(
                    watermarkText,
                    style: pw.TextStyle(
                      color: PdfColors.grey400,
                      fontSize: 18,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    final dirPath = customDirectory ?? (await FileStorageService.getCCPdfDirectory()).path;
    final file = File(p.join(dirPath, '$fileName.pdf'));

    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Merge multiple existing PDFs into one
  static Future<File> mergePdfs(List<String> pdfPaths, String outputName) async {
    await FileStorageService.requestPermissions();
    final pdf = pw.Document();

    for (final path in pdfPaths) {
      final bytes = await File(path).readAsBytes();
      // Reduced DPI to 72 (Screen standard) to prevent GLES crash on heavy files
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        final pngBytes = await page.toPng();
        final image = pw.MemoryImage(pngBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => pw.Center(child: pw.Image(image)),
          ),
        );
      }
    }

    final dir = await FileStorageService.getCCPdfDirectory();
    final file = File(p.join(dir.path, '$outputName.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Convert each image into a separate single-page PDF with watermark
  static Future<List<File>> imagesToSeparatePdfs(List<String> imagePaths, String baseName, {PdfExportProfile profile = PdfExportProfile.standard, String? customDirectory, bool addWatermark = true}) async {
    await FileStorageService.requestPermissions();
    final dirPath = customDirectory ?? (await FileStorageService.getCCPdfDirectory()).path;
    final List<File> files = [];

    for (int i = 0; i < imagePaths.length; i++) {
      final pdf = pw.Document();
      final processedBytes = await _processImageForProfile(imagePaths[i], profile);
      final image = pw.MemoryImage(processedBytes);

      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                if (addWatermark)
                  pw.Positioned(
                    bottom: 20,
                    right: 20,
                    child: pw.Text(
                      watermarkText,
                      style: pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      final file = File(p.join(dirPath, '${baseName}_${i + 1}.pdf'));

      await file.writeAsBytes(await pdf.save());
      files.add(file);
    }

    return files;
  }

  /// Process multiple images and save them as separate compressed JPG files
  static Future<List<File>> processImages(List<String> imagePaths, String baseName, {PdfExportProfile profile = PdfExportProfile.standard, String? customDirectory, bool addWatermark = false}) async {
    await FileStorageService.requestPermissions();
    final dirPath = customDirectory ?? (await FileStorageService.getCCPdfDirectory()).path;
    final List<File> files = [];

    for (int i = 0; i < imagePaths.length; i++) {
      Uint8List processedBytes = await _processImageForProfile(imagePaths[i], profile);
      if (addWatermark) {
        processedBytes = _addWatermarkToImage(processedBytes);
      }
      final file = File(p.join(dirPath, '${baseName}_${i + 1}.jpg'));
      await file.writeAsBytes(processedBytes);
      files.add(file);
    }

    return files;
  }

  /// Convert PDF pages to images with watermark using image package
  static Future<List<File>> pdfToImages(String pdfPath, {bool addWatermark = true}) async {
    await FileStorageService.requestPermissions();
    final dir = await FileStorageService.getCCPdfDirectory();
    final bytes = await File(pdfPath).readAsBytes();
    final List<File> imageFiles = [];
    final baseName = p.basenameWithoutExtension(pdfPath);

    int i = 1;
    await for (final page in Printing.raster(bytes, dpi: 72)) {
      final pngBytes = await page.toPng();
      
      // Add watermark to the image if requested
      final finalBytes = addWatermark ? _addWatermarkToImage(pngBytes) : pngBytes;
      
      final file = File(p.join(dir.path, '${baseName}_page_$i.png'));
      await file.writeAsBytes(finalBytes);
      imageFiles.add(file);
      i++;
    }

    return imageFiles;
  }

  /// Add watermark text to image bytes
  static Uint8List _addWatermarkToImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Use a larger font for images
    img.drawString(
      image,
      watermarkText,
      font: img.arial48,
      x: image.width - 450,
      y: image.height - 80,
      color: img.ColorRgba8(150, 150, 150, 180),
    );

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Render PDF pages as image bytes for preview (no watermark for preview)
  static Future<List<Uint8List>> renderPdfPages(String pdfPath) async {
    final bytes = await File(pdfPath).readAsBytes();
    final List<Uint8List> pages = [];

    await for (final page in Printing.raster(bytes, dpi: 100)) {
      final pngBytes = await page.toPng();
      pages.add(Uint8List.fromList(pngBytes));
    }

    return pages;
  }

  /// Process image according to the selected profile (Resize and Compress)
  static Future<Uint8List> _processImageForProfile(String path, PdfExportProfile profile) async {
    final bytes = await File(path).readAsBytes();
    if (profile == PdfExportProfile.standard) return bytes;

    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    int? targetWidth;
    int quality = 85;

    switch (profile) {
      case PdfExportProfile.government:
        targetWidth = 1500;
        quality = 70;
        break;
      case PdfExportProfile.embassy:
        targetWidth = 2000;
        quality = 80;
        break;
      case PdfExportProfile.maxCompression:
        targetWidth = 1000;
        quality = 50;
        break;
      default:
        return bytes;
    }

    img.Image resized = image;
    if (image.width > targetWidth) {
      resized = img.copyResize(image, width: targetWidth);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }
}

