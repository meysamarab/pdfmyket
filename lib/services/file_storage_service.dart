import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';

class FileStorageService {
  static const String _folderName = 'CCPdf';

  /// Request necessary permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      // For Android 13+ (API 33), we might need photos/videos permissions, 
      // but for general storage, 'storage' is still used in many plugins.
      // However, Scoped Storage is the real issue.
      
      if (status.isGranted) return true;
      
      // Try MANAGE_EXTERNAL_STORAGE for Android 11+ if regular storage is denied
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      
      return false;
    }
    return true;
  }

  /// Get or create the CCPdf directory
  static Future<Directory> getCCPdfDirectory() async {
    Directory? baseDir;
    
    if (Platform.isAndroid) {
      // Try to get public external storage first
      try {
        // On Android 11+, this will fail to create at root without MANAGE_EXTERNAL_STORAGE
        // So we fallback to app-specific external storage which is always granted
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
        if (extDirs != null && extDirs.isNotEmpty) {
          baseDir = extDirs.first;
        }
      } catch (e) {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    baseDir ??= await getApplicationDocumentsDirectory();

    // Create the CCPdf folder inside the base directory
    final ccPdfDir = Directory(p.join(baseDir.path, _folderName));
    if (!await ccPdfDir.exists()) {
      await ccPdfDir.create(recursive: true);
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
