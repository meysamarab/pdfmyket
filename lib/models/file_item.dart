import 'dart:io';

enum AppFileType { pdf, image }

class FileItem {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;
  final AppFileType type;

  FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  String get sizeString {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
