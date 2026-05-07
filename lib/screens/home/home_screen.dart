import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';
import '../camera/multi_capture_screen.dart';
import '../editor/reorder_pages_screen.dart';
import '../camera/id_card_capture_screen.dart';
import '../pdf/merge_pdf_screen.dart';
import '../pdf/import_pdf_screen.dart';
import '../pdf/compress_document_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImages(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final appState = Provider.of<AppState>(context, listen: false);

    if (source == ImageSource.camera) {
      final List<String>? result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(builder: (context) => const MultiCaptureScreen()),
      );
      
      if (result != null && result.isNotEmpty && context.mounted) {
        appState.addImages(result);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReorderPagesScreen()));
      }
    } else {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        appState.addImages(images.map((e) => e.path).toList());
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReorderPagesScreen()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header: Logo and Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سی‌سی‌اسکنر',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      Text(
                        'CCScaner',
                        style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // Green Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF00D191)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تبدیل سریع عکس\nعکس به پی‌دی‌اف',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'با کیفیت بالا و به سادگی',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _pickImages(context, ImageSource.gallery),
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                      label: const Text('انتخاب عکس یا گرفتن عکس', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Tools Section
              const Text(
                'ابزارهای کاربردی',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildToolCard(
                    context,
                    title: 'اسکن کارت شناسایی',
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IdCardCaptureScreen())),
                  ),
                  _buildToolCard(
                    context,
                    title: 'ادغام فایل‌ها',
                    icon: Icons.merge_type,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MergePdfScreen())),
                  ),
                  _buildToolCard(
                    context,
                    title: 'تبدیل پی‌دی‌اف به عکس',
                    icon: Icons.picture_as_pdf,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportPdfScreen())),
                  ),
                  _buildToolCard(
                    context,
                    title: 'تنظیم سند بارگذاری',
                    icon: Icons.auto_fix_high_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompressDocumentScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Recent Scans Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اسکن‌های اخیر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Provider.of<AppState>(context, listen: false).setTabIndex(1),
                    child: const Text('مشاهده همه', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentGrid(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGrid(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.recentFiles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.history, size: 50, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  const Text('هنوز اسکن جدیدی ندارید', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.recentFiles.length > 4 ? 4 : state.recentFiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final file = state.recentFiles[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => OpenFilex.open(file.path),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('مشاهده', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
