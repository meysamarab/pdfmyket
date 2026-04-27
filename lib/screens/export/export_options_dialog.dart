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
  String _format = 'JPG';
  String _quality = 'High';
  String _exportMode = 'Separate';

  Future<void> _handleExport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Navigate to processing screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProcessingScreen()),
    );

    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      final file = await PdfService.imagesToPdf(
        appState.selectedImagePaths,
        'Export_${DateTime.now().millisecondsSinceEpoch}',
      );

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
        // Replace processing screen with result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(fileItem: fileItem)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Go back from processing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
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
              'تنظیمات خروجی',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'نحوه ذخیره فایل‌های خود را تنظیم کنید.',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            
            // Format Section
            _buildBentoSection(
              title: 'فرمت',
              icon: Icons.image,
              child: _buildToggleGroup(
                options: ['JPG', 'PNG'],
                selected: _format,
                onSelected: (val) => setState(() => _format = val),
              ),
            ),
            const SizedBox(height: 16),
            
            // Quality Section
            _buildBentoSection(
              title: 'کیفیت',
              icon: Icons.high_quality,
              child: _buildToggleGroup(
                options: ['Low', 'Medium', 'High'],
                selected: _quality,
                onSelected: (val) => setState(() => _quality = val),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'حالت خروجی',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            
            // Export Mode Options
            _buildOptionCard(
              title: 'تصاویر جداگانه',
              subtitle: 'ذخیره به صورت فایل‌های مجزا',
              icon: Icons.photo_library,
              isSelected: _exportMode == 'Separate',
              onTap: () => setState(() => _exportMode = 'Separate'),
            ),
            const SizedBox(height: 8),
            _buildOptionCard(
              title: 'فایل ZIP تکی',
              subtitle: 'فشرده‌سازی همه در یک فایل آرشیو',
              icon: Icons.folder_zip,
              isSelected: _exportMode == 'Zip',
              onTap: () => setState(() => _exportMode = 'Zip'),
            ),
            
            const SizedBox(height: 40),
            
            // Export Button
            ElevatedButton.icon(
              onPressed: _handleExport,
              icon: const Icon(Icons.ios_share, size: 20),
              label: const Text('خروجی گرفتن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
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

  Widget _buildBentoSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Icon(icon, color: AppColors.outline, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleGroup({required List<String> options, required String selected, required ValueChanged<String> onSelected}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                  border: isSelected ? Border.all(color: AppColors.surfaceContainerHighest.withOpacity(0.5)) : null,
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
          color: isSelected ? AppColors.primaryContainer.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
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
