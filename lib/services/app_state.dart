import 'package:flutter/material.dart';
import '../models/file_item.dart';

class AppState extends ChangeNotifier {
  List<String> _selectedImagePaths = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  List<FileItem> _recentFiles = [];

  List<String> get selectedImagePaths => _selectedImagePaths;
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  List<FileItem> get recentFiles => _recentFiles;

  void addImages(List<String> paths) {
    _selectedImagePaths.addAll(paths);
    notifyListeners();
  }

  void removeImage(int index) {
    _selectedImagePaths.removeAt(index);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = _selectedImagePaths.removeAt(oldIndex);
    _selectedImagePaths.insert(newIndex, item);
    notifyListeners();
  }

  void clearImages() {
    _selectedImagePaths.clear();
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void updateProgress(double value) {
    _processingProgress = value;
    notifyListeners();
  }

  void addRecentFile(FileItem file) {
    _recentFiles.insert(0, file);
    if (_recentFiles.length > 10) _recentFiles.removeLast();
    notifyListeners();
  }
}
