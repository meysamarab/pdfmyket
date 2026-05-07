import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../../models/file_item.dart';
import '../../services/file_storage_service.dart';
import '../common/processing_screen.dart';
import '../result/result_screen.dart';
import '../common/subscription_dialog.dart';

class CompressDocumentScreen extends StatefulWidget {
  const CompressDocumentScreen({super.key});

  @override
  State<CompressDocumentScreen> createState() => _CompressDocumentScreenState();
}

class _CompressDocumentScreenState extends State<CompressDocumentScreen> {
  List<String> _selectedFilePaths = [];
  bool _isPdf = false;
  PdfExportProfile _selectedProfile = PdfExportProfile.government;
  bool _isCustomLocationEnabled = false;
  String _outputFormat = 'PDF'; // PDF or Image
  bool _removeWatermark = false;

  Future<void> _pickFiles() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'انتخاب فایل برای تنظیم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.image_outlined,
                    label: 'تصاویر',
                    onTap: () async {
                      Navigator.pop(context);
                      final picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setState(() {
                          _selectedFilePaths = images.map((e) => e.path).toList();
                          _isPdf = false;
                          _outputFormat = 'PDF'; // Default to PDF
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'فایل PDF',
                    onTap: () async {
                      Navigator.pop(context);
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          _selectedFilePaths = [result.files.single.path!];
                          _isPdf = true;
                          _outputFormat = 'PDF';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withOpacity(0.02),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProcess() async {
    if (_selectedFilePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا ابتدا فایل را انتخاب کنید')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    // Subscription Checks
    final bool needsSubForWatermark = _removeWatermark && !appState.canUseFeature('watermark');
    final bool needsSubForAdjust = !appState.canUseFeature('adjust');

    if (needsSubForWatermark || needsSubForAdjust) {
      SubscriptionDialog.show(context);
      return;
    }

    final hasPermission = await FileStorageService.requestPermissions();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای ذخیره فایل نیاز به دسترسی حافظه است')),
      );
      return;
    }

    String? customPath;
    if (_isCustomLocationEnabled) {
      customPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'انتخاب محل ذخیره فایل',
      );
      if (customPath == null) return;
    } else {
      customPath = appState.defaultStoragePath;
    }

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProcessingScreen()),
    );

    try {
      final baseName = 'Adjusted_${DateTime.now().millisecondsSinceEpoch}';
      File? resultFile;

      if (_isPdf) {
        // PDF Processing: Rasterize then re-compress
        final List<File> imageFiles = await PdfService.pdfToImages(_selectedFilePaths.first, addWatermark: false);
        final List<String> tempPaths = imageFiles.map((e) => e.path).toList();
        
        resultFile = await PdfService.imagesToPdf(
          tempPaths, 
          baseName,
          profile: _selectedProfile,
          customDirectory: customPath,
          addWatermark: !_removeWatermark,
        );

        // Cleanup temp images
        for (final f in imageFiles) {
          if (await f.exists()) await f.delete();
        }
      } else {
        // Image Processing
        if (_outputFormat == 'PDF') {
          resultFile = await PdfService.imagesToPdf(
            _selectedFilePaths, 
            baseName,
            profile: _selectedProfile,
            customDirectory: customPath,
            addWatermark: !_removeWatermark,
          );
        } else {
          // Output as Image
          final List<File> processedImages = await PdfService.processImages(
            _selectedFilePaths, 
            baseName,
            profile: _selectedProfile,
            customDirectory: customPath,
          );
          if (processedImages.isNotEmpty) {
            resultFile = processedImages.first; // Return first one for result screen
            // Add others to recent files
            for (int i = 1; i < processedImages.length; i++) {
              final f = processedImages[i];
              appState.addRecentFile(FileItem(
                id: 'img_${f.path.hashCode}',
                name: f.path.split(Platform.pathSeparator).last,
                path: f.path,
                size: await f.length(),
                createdAt: DateTime.now(),
                type: AppFileType.image,
              ));
            }
          }
        }
      }
      
      if (resultFile != null) {
        if (!appState.isSubscribed) {
          appState.setTrialUsed('adjust');
          if (_removeWatermark) {
            appState.setTrialUsed('watermark');
          }
        }

        final fileItem = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: resultFile.path.split(Platform.pathSeparator).last,
          path: resultFile.path,
          size: await resultFile.length(),
          createdAt: DateTime.now(),
          type: _outputFormat == 'PDF' ? AppFileType.pdf : AppFileType.image,
        );

        appState.addRecentFile(fileItem);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(fileItem: fileItem)),
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در پردازش فایل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تنظیم برای بارگذاری',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('انتخاب فایل', 'عکس یا سند PDF مورد نظر خود را انتخاب کنید'),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickFiles,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    if (_selectedFilePaths.isEmpty) ...[
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      const Text('برای انتخاب فایل کلیک کنید', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ] else ...[
                      Icon(_isPdf ? Icons.picture_as_pdf : Icons.image, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        _isPdf 
                          ? _selectedFilePaths.first.split(Platform.pathSeparator).last 
                          : '${_selectedFilePaths.length} تصویر انتخاب شده',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('برای تغییر کلیک کنید', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),

            if (!_isPdf && _selectedFilePaths.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionTitle('فرمت خروجی', 'انتخاب کنید فایل نهایی چه فرمتی باشد'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'فایل PDF',
                      isSelected: _outputFormat == 'PDF',
                      onTap: () => setState(() => _outputFormat = 'PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'عکس (JPG)',
                      isSelected: _outputFormat == 'Image',
                      onTap: () => setState(() => _outputFormat = 'Image'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            _buildSectionTitle('تنظیمات کاهش حجم', 'بهینه‌سازی فایل برای سامانه‌های مختلف'),
            const SizedBox(height: 16),
            _buildProfileOption('استاندارد (کیفیت بالا)', 'بدون کاهش حجم اضافی', PdfExportProfile.standard, Icons.high_quality),
            _buildProfileOption('وب‌سایت‌های دولتی', 'حجم زیر 2 مگابایت', PdfExportProfile.government, Icons.account_balance),
            _buildProfileOption('سفارت‌ها', 'حجم زیر 2.5 مگابایت', PdfExportProfile.embassy, Icons.language),
            _buildProfileOption('حداکثر کاهش حجم', 'حجم زیر 1 مگابایت', PdfExportProfile.maxCompression, Icons.compress),

            const SizedBox(height: 24),
            SwitchListTile(
              value: _removeWatermark,
              onChanged: (val) => setState(() => _removeWatermark = val),
              title: Row(
                children: [
                  const Text('حذف واترمارک برنامه', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  if (!appState.isSubscribed) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Text('ویژه', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: const Text('حذف متن "Created by CCScaner" از فایل نهایی', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isCustomLocationEnabled,
              onChanged: (val) => setState(() => _isCustomLocationEnabled = val),
              title: const Text('انتخاب محل ذخیره توسط من', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('اگر غیرفعال باشد، در پوشه CCPdf ذخیره می‌شود', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: _handleProcess,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
              label: const Text('پردازش و ذخیره'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5)),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(String title, String subtitle, PdfExportProfile profile, IconData icon) {
    final isSelected = _selectedProfile == profile;
    return InkWell(
      onTap: () => setState(() => _selectedProfile = profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.outline, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? AppColors.primary : AppColors.onSurface)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
