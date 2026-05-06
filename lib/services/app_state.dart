import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';
import 'file_storage_service.dart';

class AppState extends ChangeNotifier {
  List<String> _selectedImagePaths = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  List<FileItem> _recentFiles = [];
  int _currentTabIndex = 0;
  String? _defaultStoragePath;

  List<String> get selectedImagePaths => _selectedImagePaths;
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  List<FileItem> get recentFiles => _recentFiles;
  int get currentTabIndex => _currentTabIndex;
  String? get defaultStoragePath => _defaultStoragePath;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  AppState() {
    _loadSettings();
    loadRecentFiles();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultStoragePath = prefs.getString('defaultStoragePath');
    notifyListeners();
  }

  Future<void> setDefaultStoragePath(String? path) async {
    _defaultStoragePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('defaultStoragePath');
    } else {
      await prefs.setString('defaultStoragePath', path);
    }
    await loadRecentFiles(); // Reload files from new path
    notifyListeners();
  }

  /// Load recent files from the current storage directory
  Future<void> loadRecentFiles() async {
    try {
      _recentFiles = await FileStorageService.listFiles(customPath: _defaultStoragePath);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent files: $e');
    }
  }

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

  void updateImagePath(int index, String newPath) {
    if (index >= 0 && index < _selectedImagePaths.length) {
      _selectedImagePaths[index] = newPath;
      notifyListeners();
    }
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
    notifyListeners();
  }

  Future<void> removeRecentFile(String path) async {
    try {
      await FileStorageService.deleteFile(path);
      _recentFiles.removeWhere((f) => f.path == path);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
