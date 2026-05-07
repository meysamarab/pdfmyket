import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';
import 'file_storage_service.dart';
import 'billing_service.dart';

class AppState extends ChangeNotifier {
  List<String> _selectedImagePaths = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  List<FileItem> _recentFiles = [];
  int _currentTabIndex = 0;
  String? _defaultStoragePath;

  bool _isPremium = false;
  bool _watermarkTrialUsed = false;
  bool _mergeTrialUsed = false;
  bool _adjustTrialUsed = false;

  bool get isPremium => _isPremium;
  bool get watermarkTrialUsed => _watermarkTrialUsed;
  bool get mergeTrialUsed => _mergeTrialUsed;
  bool get adjustTrialUsed => _adjustTrialUsed;

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
    _initBilling();
  }

  Future<void> _initBilling() async {
    await BillingService.init();
    _isPremium = await BillingService.checkPurchaseStatus();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultStoragePath = prefs.getString('defaultStoragePath');
    _watermarkTrialUsed = prefs.getBool('watermarkTrialUsed') ?? false;
    _mergeTrialUsed = prefs.getBool('mergeTrialUsed') ?? false;
    _adjustTrialUsed = prefs.getBool('adjustTrialUsed') ?? false;
    notifyListeners();
  }

  Future<void> setTrialUsed(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    if (feature == 'watermark') {
      _watermarkTrialUsed = true;
      await prefs.setBool('watermarkTrialUsed', true);
    } else if (feature == 'merge') {
      _mergeTrialUsed = true;
      await prefs.setBool('mergeTrialUsed', true);
    } else if (feature == 'adjust') {
      _adjustTrialUsed = true;
      await prefs.setBool('adjustTrialUsed', true);
    }
    notifyListeners();
  }

  Future<void> refreshPremiumStatus() async {
    _isPremium = await BillingService.checkPurchaseStatus();
    notifyListeners();
  }

  Future<void> purchasePremium() async {
    final success = await BillingService.purchase();
    if (success) {
      _isPremium = true;
      notifyListeners();
    }
  }

  /// Check if user can use a premium feature.
  /// Premium users: always true.
  /// Free users: first time free, then must purchase.
  bool canUseFeature(String feature) {
    if (_isPremium) return true;
    if (feature == 'watermark') return !_watermarkTrialUsed;
    if (feature == 'merge') return !_mergeTrialUsed;
    if (feature == 'adjust') return !_adjustTrialUsed;
    return false;
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
