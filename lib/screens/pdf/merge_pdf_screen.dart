import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../result/result_screen.dart';
import '../common/subscription_dialog.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<FileItem> _selectedFiles = [];
  bool _isMerging = false;

  void _toggleSelection(FileItem file) {
    setState(() {
      final index = _selectedFiles.indexWhere((f) => f.path == file.path);
      if (index != -1) {
        _selectedFiles.removeAt(index);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  Future<void> _pickExternalPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            final fileItem = FileItem(
              id: 'ext_${DateTime.now().millisecondsSinceEpoch}_${file.path.hashCode}',
              name: file.name,
              path: file.path!,
              size: file.size,
              createdAt: DateTime.now(),
              type: AppFileType.pdf,
            );
            if (!_selectedFiles.any((f) => f.path == fileItem.path)) {
              _selectedFiles.add(fileItem);
            }
          }
        }
      });
    }
  }

  Future<void> _mergeFiles() async {
    if (_selectedFiles.length < 2) return;

    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.canUseFeature('merge')) {
      SubscriptionDialog.show(context);
      return;
    }

    setState(() => _isMerging = true);

    try {
      final paths = _selectedFiles.map((e) => e.path).toList();
      final outputName = 'Merged_${DateTime.now().millisecondsSinceEpoch}';
      final file = await PdfService.mergePdfs(paths, outputName);

      if (mounted) {
        // Mark trial as used if not subscribed
        if (!appState.isSubscribed) {
          appState.setTrialUsed('merge');
        }

        final fileItem = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.path.split(Platform.pathSeparator).last,
          path: file.path,
          size: await file.length(),
          createdAt: DateTime.now(),
          type: AppFileType.pdf,
        );

        Provider.of<AppState>(context, listen: false).addRecentFile(fileItem);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(fileItem: fileItem),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ادغام فایل‌ها: $e')),
        );
      }
    } finally {
      setState(() => _isMerging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentPdfFiles = Provider.of<AppState>(context)
        .recentFiles
        .where((f) => f.type == AppFileType.pdf)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ادغام فایل‌های PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _pickExternalPdf,
            icon: const Icon(Icons.add_link_rounded, color: AppColors.primary),
            tooltip: 'انتخاب فایل از دستگاه',
          ),
        ],
      ),
      body: _isMerging
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedFiles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ترتیب فایل‌ها (بکشید و رها کنید)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('${_selectedFiles.length} فایل انتخاب شده', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: ReorderableListView.builder(
                        itemCount: _selectedFiles.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final item = _selectedFiles.removeAt(oldIndex);
                            _selectedFiles.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return ListTile(
                            key: ValueKey(file.path),
                            leading: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                            title: Text(file.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(file.sizeString, style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _toggleSelection(file),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('فایل‌های اخیر برنامه', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (recentPdfFiles.isEmpty) const Text('فایلی یافت نشد', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: recentPdfFiles.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            const Text('فایل اخیری وجود ندارد', style: TextStyle(color: Colors.grey)),
                            TextButton.icon(
                              onPressed: _pickExternalPdf, 
                              icon: const Icon(Icons.add), 
                              label: const Text('انتخاب از حافظه گوشی')
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: recentPdfFiles.length,
                        itemBuilder: (context, index) {
                          final file = recentPdfFiles[index];
                          final isSelected = _selectedFiles.any((f) => f.path == file.path);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.picture_as_pdf, color: isSelected ? AppColors.primary : Colors.grey),
                              title: Text(file.name, style: const TextStyle(fontSize: 13)),
                              subtitle: Text(file.sizeString, style: const TextStyle(fontSize: 11)),
                              trailing: Icon(
                                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                color: isSelected ? AppColors.primary : Colors.grey,
                              ),
                              onTap: () => _toggleSelection(file),
                            ),
                          );
                        },
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _selectedFiles.length >= 2 ? _mergeFiles : null,
                      icon: const Icon(Icons.merge_type),
                      label: const Text('ادغام و ساخت فایل نهایی'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
