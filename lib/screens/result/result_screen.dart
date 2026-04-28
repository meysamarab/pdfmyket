import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/file_storage_service.dart';

class ResultScreen extends StatelessWidget {
  final FileItem fileItem;
  const ResultScreen({super.key, required this.fileItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'فایل آماده است',
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
          children: [
            // Success Indicator Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 48,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تبدیل با موفقیت انجام شد',
                    style: TextStyle(
                      color: Color(0xFF27AE60),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fileItem.sizeString} • ${fileItem.type == AppFileType.pdf ? "PDF" : "Image"}',
                    style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Filename Input
            TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                suffixIcon: const Icon(Icons.edit, size: 20),
              ),
              controller: TextEditingController(text: fileItem.name),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 32),
            
            // Share Button
            ElevatedButton.icon(
              onPressed: () {
                Share.shareXFiles([XFile(fileItem.path)], text: 'Check out my file!');
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text('اشتراک‌گذاری فایل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: const Color(0xFF27AE60).withOpacity(0.25),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Secondary Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(Icons.open_in_new, 'مشاهده فایل', onTap: () {
                  OpenFilex.open(fileItem.path);
                }),
                _buildActionCard(Icons.save_alt, 'ذخیره در...', onTap: () async {
                  try {
                    // Check if we have permission first
                    if (Platform.isAndroid) {
                      final status = await Permission.manageExternalStorage.status;
                      if (!status.isGranted) {
                        // Show a dialog explaining why we need this
                        if (context.mounted) {
                          bool? proceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('دسترسی به فایل‌ها'),
                              content: const Text(
                                'برای ذخیره فایل در پوشه دلخواه، باید دسترسی "مدیریت تمام فایل‌ها" را در صفحه بعدی فعال کنید.',
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تایید و رفتن به تنظیمات')),
                              ],
                            ),
                          );
                          
                          if (proceed != true) return;
                        }
                        
                        // Request permission
                        final result = await Permission.manageExternalStorage.request();
                        if (!result.isGranted) return;
                      }
                    }

                    String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath();
                    if (selectedDirectory != null) {
                      final File sourceFile = File(fileItem.path);
                      final String destPath = p.join(selectedDirectory, fileItem.name);
                      
                      // Perform copy
                      await sourceFile.copy(destPath);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فایل در پوشه مورد نظر ذخیره شد')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا در ذخیره‌سازی: $e (مطمئن شوید دسترسی مدیریت فایل را فعال کرده‌اید)')),
                      );
                    }
                  }
                }),
                _buildActionCard(Icons.print, 'چاپ', onTap: () {
                  // Print logic could be added here
                }),
                _buildActionCard(Icons.drive_file_rename_outline, 'تغییر نام', onTap: () {}),
                _buildActionCard(Icons.delete, 'حذف', isError: true, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, {bool isError = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isError ? AppColors.error.withOpacity(0.05) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isError ? AppColors.error.withOpacity(0.3) : AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isError ? AppColors.error : AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isError ? AppColors.error : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
