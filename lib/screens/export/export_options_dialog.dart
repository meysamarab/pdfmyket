import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../../models/file_item.dart';
import '../common/processing_screen.dart';
import '../result/result_screen.dart';

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({super.key});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  String _exportMode = 'Single'; // Single PDF or Separate PDFs

  Future<void> _handleExport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProcessingScreen()),
    );

    try {
      final baseName = 'CCPdf_${DateTime.now().millisecondsSinceEpoch}';
      
      if (_exportMode == 'Single') {
        final file = await PdfService.imagesToPdf(appState.selectedImagePaths, baseName);
        
        final fileItem = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.path.split('/').last,
          path: file.path,
          size: await file.length(),
          createdAt: DateTime.now(),
          type: FileType.pdf,
        );

        appState.addRecentFile(fileItem);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(fileItem: fileItem)),
          );
        }
      } else {
        // Separate PDFs
        final files = await PdfService.imagesToSeparatePdfs(appState.selectedImagePaths, baseName);
        
        // Add all to recent files (last one will be shown in result screen)
        FileItem? lastItem;
        for (final file in files) {
          lastItem = FileItem(
            id: file.path.hashCode.toString(),
            name: file.path.split('/').last,
            path: file.path,
            size: await file.length(),
            createdAt: DateTime.now(),
            type: FileType.pdf,
          );
          appState.addRecentFile(lastItem);
        }

        if (mounted && lastItem != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(fileItem: lastItem!)),
          );
        }
      }
      
      // Clear selection after success
      appState.clearImages();
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Go back from processing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی گرفتن: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'حالت خروجی',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'نحوه ذخیره فایل‌های خود را انتخاب کنید.',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            _buildOptionCard(
              title: 'خروجی در یک فایل PDF',
              subtitle: 'همه تصاویر در یک فایل چند صفحه‌ای ذخیره می‌شوند',
              icon: Icons.picture_as_pdf,
              isSelected: _exportMode == 'Single',
              onTap: () => setState(() => _exportMode = 'Single'),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              title: 'خروجی در فایل‌های جداگانه',
              subtitle: 'هر تصویر در یک فایل PDF جداگانه ذخیره می‌شود',
              icon: Icons.copy_all,
              isSelected: _exportMode == 'Separate',
              onTap: () => setState(() => _exportMode = 'Separate'),
            ),
            
            const SizedBox(height: 60),
            
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary.withOpacity(0.8) : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
