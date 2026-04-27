import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';
import '../editor/reorder_pages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImages(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (source == ImageSource.camera) {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        appState.addImages([photo.path]);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReorderPagesScreen()),
          );
        }
      }
    } else {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        appState.addImages(images.map((e) => e.path).toList());
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReorderPagesScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {},
        ),
        title: Text(
          'تصویر به پی‌دی‌اف', // Image to PDF
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
            _buildHeroCard(
              context,
              title: 'اسکن با دوربین',
              icon: Icons.camera_alt,
              isPrimary: true,
              onTap: () => _pickImages(context, ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _buildHeroCard(
              context,
              title: 'انتخاب از گالری',
              icon: Icons.image,
              isPrimary: false,
              onTap: () => _pickImages(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            _buildHeroCard(
              context,
              title: 'پی‌دی‌اف به تصویر',
              icon: Icons.picture_as_pdf,
              isPrimary: false,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فایل‌های اخیر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'مشاهده همه',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentFileList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.outlineVariant, width: 1),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isPrimary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFileList(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.recentFiles.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, size: 48, color: AppColors.outline),
                SizedBox(height: 16),
                Text(
                  'هنوز فایلی ساخته نشده است',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.recentFiles.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.outlineVariant.withOpacity(0.3),
              indent: 70,
            ),
            itemBuilder: (context, index) {
              final file = state.recentFiles[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: file.type == FileType.pdf ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    file.type == FileType.pdf ? Icons.picture_as_pdf : Icons.image,
                    color: file.type == FileType.pdf ? const Color(0xFFD32F2F) : const Color(0xFF1976D2),
                  ),
                ),
                title: Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                subtitle: Text(
                  '${file.sizeString} • ${file.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    OpenFile.open(file.path);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
