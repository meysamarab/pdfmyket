import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';

class FileStorageService {
  static const String _folderName = 'CCScaner'; // Name of subfolder in Download

  /// Request necessary permissions including Manage External Storage for root access
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Check if we already have it
      if (await Permission.manageExternalStorage.isGranted) return true;

      // Request it (this will open system settings on Android 11+)
      final status = await Permission.manageExternalStorage.request();
      
      if (status.isGranted) return true;

      // If permanently denied, user needs to manually enable it in app settings
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      
      // Fallback for older Android versions
      if (await Permission.storage.request().isGranted) return true;
      
      return false;
    }
    return true;
  }

  /// Get or create the CCPdf directory in the device root (public storage)
  static Future<Directory> getCCPdfDirectory() async {
    Directory? baseDir;
    
    if (Platform.isAndroid) {
      // Direct access to Public Download folder
      baseDir = Directory('/storage/emulated/0/Download');
      
      if (!await baseDir.exists()) {
        // Fallback for some devices/versions
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

  /// List all files in the CCPdf directory or a custom directory
  static Future<List<FileItem>> listFiles({String? customPath}) async {
    final Directory dir;
    if (customPath != null) {
      dir = Directory(customPath);
    } else {
      dir = await getCCPdfDirectory();
    }
    
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
          
          if (ext == '.pdf' || ext == '.png' || ext == '.jpg' || ext == '.jpeg') {
            items.add(FileItem(
              id: entity.path.hashCode.toString(),
              name: name,
              path: entity.path,
              size: stat.size,
              createdAt: stat.modified,
              type: ext == '.pdf' ? AppFileType.pdf : AppFileType.image,
            ));
          }
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
