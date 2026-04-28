import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';

class FileStorageService {
  static const String _folderName = 'CCPdf';

  /// Request necessary permissions including Manage External Storage for root access
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+, we need Manage External Storage to write to root
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;

      // Fallback to regular storage for older versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  /// Get or create the CCPdf directory in the device root (public storage)
  static Future<Directory> getCCPdfDirectory() async {
    Directory? baseDir;
    
    if (Platform.isAndroid) {
      // This path is the "Root" of the internal storage accessible by user
      baseDir = Directory('/storage/emulated/0');
      
      // Verify if we can write to it, otherwise fallback
      if (!await baseDir.exists()) {
        final extDir = await getExternalStorageDirectory();
        baseDir = extDir;
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    baseDir ??= await getApplicationDocumentsDirectory();

    // Create the CCPdf folder in the root
    final ccPdfDir = Directory(p.join(baseDir.path, _folderName));
    if (!await ccPdfDir.exists()) {
      try {
        await ccPdfDir.create(recursive: true);
      } catch (e) {
        // Final fallback to documents if root creation fails
        final docDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory(p.join(docDir.path, _folderName));
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    }
    return ccPdfDir;
  }

  /// Save a file to the CCPdf directory
  static Future<File> saveFile(File source, String fileName) async {
    await requestPermissions();
    final dir = await getCCPdfDirectory();
    final destPath = p.join(dir.path, fileName);
    return source.copy(destPath);
  }

  /// List all files in the CCPdf directory
  static Future<List<FileItem>> listFiles() async {
    final dir = await getCCPdfDirectory();
    final List<FileItem> items = [];

    if (!await dir.exists()) return items;

    try {
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
    } catch (e) {
      print('Error listing files: $e');
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
