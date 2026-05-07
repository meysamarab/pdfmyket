import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../../models/file_item.dart';
import '../../services/file_storage_service.dart';
import '../common/processing_screen.dart';
import '../result/result_screen.dart';
import '../common/subscription_dialog.dart';


class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({super.key});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  String _exportMode = 'Single'; // Single PDF or Separate PDFs
  PdfExportProfile _selectedProfile = PdfExportProfile.standard;
  bool _isCustomLocationEnabled = false;
  bool _removeWatermark = false;

  Future<void> _handleExport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (_removeWatermark && !appState.canUseFeature('watermark')) {
      SubscriptionDialog.show(context);
      return;
    }


    final hasPermission = await FileStorageService.requestPermissions();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای ذخیره فایل نیاز به دسترسی حافظه است')),
      );
    }

    String? customPath;
    if (_isCustomLocationEnabled) {
      customPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'انتخاب محل ذخیره فایل',
      );
      if (customPath == null) return; // User cancelled
    } else {
      // Use global default if set
      customPath = appState.defaultStoragePath;
    }

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProcessingScreen()),
    );

    try {
      final baseName = 'CCPdf_${DateTime.now().millisecondsSinceEpoch}';
      
      if (_exportMode == 'Single') {
        final file = await PdfService.imagesToPdf(
          appState.selectedImagePaths, 
          baseName,
          profile: _selectedProfile,
          customDirectory: customPath,
          addWatermark: !_removeWatermark,
        );
        
        final fileItem = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.path.split(Platform.pathSeparator).last,
          path: file.path,
          size: await file.length(),
          createdAt: DateTime.now(),
          type: AppFileType.pdf,
        );

        appState.addRecentFile(fileItem);
        
        if (!appState.isPremium && _removeWatermark) {
          appState.setTrialUsed('watermark');
        }

        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(fileItem: fileItem)),
          );
        }
      } else {
        // Separate PDFs
        final files = await PdfService.imagesToSeparatePdfs(
          appState.selectedImagePaths, 
          baseName,
          profile: _selectedProfile,
          customDirectory: customPath,
        );
        
        FileItem? lastItem;
        for (final file in files) {
          lastItem = FileItem(
            id: file.path.hashCode.toString(),
            name: file.path.split(Platform.pathSeparator).last,
            path: file.path,
            size: await file.length(),
            createdAt: DateTime.now(),
            type: AppFileType.pdf,
          );
          appState.addRecentFile(lastItem);
        }

        if (!appState.isPremium && _removeWatermark) {
          appState.setTrialUsed('watermark');
        }

        if (mounted && lastItem != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(fileItem: lastItem!)),
          );
        }
      }
      
      appState.clearImages();
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی گرفتن: $e')),
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
          'تنظیمات خروجی',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant.withOpacity(0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('حالت خروجی', 'نحوه ذخیره فایل‌های خود را انتخاب کنید.'),
            const SizedBox(height: 16),
            _buildOptionCard(
              title: 'خروجی در یک فایل PDF',
              subtitle: 'همه تصاویر در یک فایل چند صفحه‌ای ذخیره می‌شوند',
              icon: Icons.picture_as_pdf,
              isSelected: _exportMode == 'Single',
              onTap: () => setState(() => _exportMode = 'Single'),
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              title: 'خروجی در فایل‌های جداگانه',
              subtitle: 'هر تصویر در یک فایل PDF جداگانه ذخیره می‌شود',
              icon: Icons.copy_all,
              isSelected: _exportMode == 'Separate',
              onTap: () => setState(() => _exportMode = 'Separate'),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('خروجی مخصوص بارگذاری (کاهش حجم)', 'بهینه‌سازی فایل برای سامانه‌های مختلف'),
            const SizedBox(height: 16),
            _buildProfileOption('استاندارد (کیفیت بالا)', 'بدون کاهش حجم اضافی', PdfExportProfile.standard, Icons.high_quality),
            _buildProfileOption('وب‌سایت‌های دولتی', 'حجم زیر 2 مگابایت', PdfExportProfile.government, Icons.account_balance),
            _buildProfileOption('سفارت‌ها', 'حجم زیر 2.5 مگابایت', PdfExportProfile.embassy, Icons.language),
            _buildProfileOption('حداکثر کاهش حجم', 'حجم زیر 1 مگابایت', PdfExportProfile.maxCompression, Icons.compress),

            const SizedBox(height: 32),
            _buildSectionTitle('محل ذخیره', 'انتخاب کنید فایل کجا ذخیره شود'),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _removeWatermark,
              onChanged: (val) => setState(() => _removeWatermark = val),
              title: Row(
                children: [
                  const Text('حذف واترمارک برنامه', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  if (!appState.isPremium)
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
              onPressed: _handleExport,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('تایید و ساخت فایل'),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
      ],
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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.onSurface)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
