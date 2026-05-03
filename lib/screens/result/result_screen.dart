import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';

class ResultScreen extends StatefulWidget {
  final FileItem fileItem;
  const ResultScreen({super.key, required this.fileItem});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FileItem currentFileItem;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    currentFileItem = widget.fileItem;
    _nameController = TextEditingController(text: currentFileItem.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _renameTo(String newName) async {
    if (newName.isEmpty || newName == currentFileItem.name) return;
    try {
      final file = File(currentFileItem.path);
      final dir = file.parent;
      final ext = currentFileItem.type == AppFileType.pdf ? '.pdf' : '.jpg';
      final finalName = newName.toLowerCase().endsWith(ext) ? newName : '$newName$ext';
      final newPath = '${dir.path}/$finalName';
      
      final renamedFile = await file.rename(newPath);
      
      setState(() {
        currentFileItem = FileItem(
          id: currentFileItem.id,
          name: finalName,
          path: renamedFile.path,
          size: currentFileItem.size,
          createdAt: currentFileItem.createdAt,
          type: currentFileItem.type,
        );
        _nameController.text = finalName;
      });
      if (mounted) {
        Provider.of<AppState>(context, listen: false).loadRecentFiles();
      }
    } catch (e) {
      debugPrint('Rename error: $e');
    }
  }

  void _showRenameDialog() {
    final TextEditingController dialogController = TextEditingController(text: currentFileItem.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تغییر نام فایل', textAlign: TextAlign.right),
          content: TextField(
            controller: dialogController,
            decoration: const InputDecoration(labelText: 'نام جدید'),
            autofocus: true,
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _renameTo(dialogController.text);
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printFile() async {
    try {
      if (currentFileItem.type == AppFileType.pdf) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => File(currentFileItem.path).readAsBytesSync(),
        );
      } else {
        final doc = pw.Document();
        final image = pw.MemoryImage(File(currentFileItem.path).readAsBytesSync());
        doc.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(child: pw.Image(image)),
          ),
        );
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => doc.save(),
        );
      }
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف فایل', textAlign: TextAlign.right),
        content: const Text('آیا از حذف این فایل مطمئن هستید؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final file = File(currentFileItem.path);
                if (await file.exists()) {
                  await file.delete();
                }
                if (mounted) {
                  Provider.of<AppState>(context, listen: false).loadRecentFiles();
                  Navigator.pop(context); // close dialog
                  Navigator.popUntil(context, (route) => route.isFirst); // go back to home
                }
              } catch (e) {
                debugPrint('Delete error: $e');
              }
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

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
                    '${currentFileItem.sizeString} • ${currentFileItem.type == AppFileType.pdf ? "PDF" : "Image"}',
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _showRenameDialog,
                ),
              ),
              controller: _nameController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              onSubmitted: _renameTo,
            ),
            
            const SizedBox(height: 32),
            
            // Share Button
            ElevatedButton.icon(
              onPressed: () {
                Share.shareXFiles([XFile(currentFileItem.path)], text: 'Check out my file!');
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
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(Icons.open_in_new, 'مشاهده فایل', onTap: () {
                  OpenFilex.open(currentFileItem.path);
                }),
                _buildActionCard(Icons.print, 'چاپ', onTap: _printFile),
                _buildActionCard(Icons.drive_file_rename_outline, 'تغییر نام', onTap: _showRenameDialog),
                _buildActionCard(Icons.delete, 'حذف', isError: true, onTap: _showDeleteDialog),
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
