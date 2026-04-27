import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfService {
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

    final output = await getTemporaryDirectory();
    final file = File(p.join(output.path, '$fileName.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // PDF to Images logic would typically need a more complex library like printing or native code, 
  // but for the sake of this UI-focused task, we'll implement the stub.
  static Future<List<File>> pdfToImages(String pdfPath) async {
    // In a real app, use a package like 'native_pdf_renderer'
    return [];
  }
}
