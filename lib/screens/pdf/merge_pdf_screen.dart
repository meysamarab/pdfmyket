import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../result/result_screen.dart';

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
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  Future<void> _mergeFiles() async {
    if (_selectedFiles.length < 2) return;

    setState(() => _isMerging = true);

    try {
      final paths = _selectedFiles.map((e) => e.path).toList();
      final outputName = 'Merged_${DateTime.now().millisecondsSinceEpoch}';
      final file = await PdfService.mergePdfs(paths, outputName);

      if (mounted) {
        final fileItem = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.path.split('/').last,
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
    final pdfFiles = Provider.of<AppState>(context)
        .recentFiles
        .where((f) => f.type == AppFileType.pdf)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ادغام فایل‌های PDF'),
        centerTitle: true,
      ),
      body: _isMerging
          ? const Center(child: CircularProgressIndicator())
          : pdfFiles.isEmpty
              ? const Center(child: Text('هیچ فایل PDF برای ادغام یافت نشد'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'حداقل ۲ فایل را برای ادغام انتخاب کنید (${_selectedFiles.length} انتخاب شده)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: pdfFiles.length,
                        itemBuilder: (context, index) {
                          final file = pdfFiles[index];
                          final isSelected = _selectedFiles.contains(file);
                          return ListTile(
                            leading: Icon(
                              Icons.picture_as_pdf,
                              color: isSelected ? AppColors.primary : Colors.grey,
                            ),
                            title: Text(file.name),
                            subtitle: Text(file.sizeString),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_off,
                              color: isSelected ? AppColors.primary : Colors.grey,
                            ),
                            onTap: () => _toggleSelection(file),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _selectedFiles.length >= 2 ? _mergeFiles : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ادغام و ساخت فایل جدید'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
