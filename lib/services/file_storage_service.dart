import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class FileStorageService {
  static const String _folderName = 'CCPdf';

  /// Get or create the CCPdf directory in external storage
  static Future<Directory> getCCPdfDirectory() async {
    final Directory baseDir;
    if (Platform.isAndroid) {
      // Use external storage on Android for user-accessible files
      final extDirs = await getExternalStorageDirectories();
      if (extDirs != null && extDirs.isNotEmpty) {
        // Go up to the root of external storage
        final parts = extDirs.first.path.split('/');
        final androidIndex = parts.indexOf('Android');
        if (androidIndex > 0) {
          baseDir = Directory(parts.sublist(0, androidIndex).join('/'));
        } else {
          baseDir = extDirs.first;
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final ccPdfDir = Directory(p.join(baseDir.path, _folderName));
    if (!await ccPdfDir.exists()) {
      await ccPdfDir.create(recursive: true);
    }
    return ccPdfDir;
  }

  /// Save a file to the CCPdf directory
  static Future<File> saveFile(File source, String fileName) async {
    final dir = await getCCPdfDirectory();
    final destPath = p.join(dir.path, fileName);
    return source.copy(destPath);
  }

  /// List all files in the CCPdf directory
  static Future<List<FileItem>> listFiles() async {
    final dir = await getCCPdfDirectory();
    final List<FileItem> items = [];

    if (!await dir.exists()) return items;

    final entities = dir.listSync()
      ..sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

    for (final entity in entities) {
      if (entity is File) {
        final stat = entity.statSync();
        final name = p.basename(entity.path);
        final ext = p.extension(entity.path).toLowerCase();
        
        items.add(FileItem(
          id: entity.path.hashCode.toString(),
          name: name,
          path: entity.path,
          size: stat.size,
          createdAt: stat.modified,
          type: ext == '.pdf' ? FileType.pdf : FileType.image,
        ));
      }
    }

    return items;
  }

  /// Delete a file
  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
