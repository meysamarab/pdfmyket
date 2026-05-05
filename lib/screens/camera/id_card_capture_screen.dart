import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';
import '../../services/pdf_service.dart';
import '../result/result_screen.dart';

class IdCardCaptureScreen extends StatefulWidget {
  const IdCardCaptureScreen({super.key});

  @override
  State<IdCardCaptureScreen> createState() => _IdCardCaptureScreenState();
}

class _IdCardCaptureScreenState extends State<IdCardCaptureScreen> {
  String? _frontPath;
  String? _backPath;
  bool _isProcessing = false;

  Future<void> _captureImage(bool isFront) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (isFront) {
          _frontPath = image.path;
        } else {
          _backPath = image.path;
        }
      });
    }
  }

  Future<void> _generatePdf() async {
    if (_frontPath == null || _backPath == null) return;

    setState(() => _isProcessing = true);

    try {
      final fileName = 'ID_Card_${DateTime.now().millisecondsSinceEpoch}';
      final file = await PdfService.generateIdCardPdf(_frontPath!, _backPath!, fileName);
      
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
          SnackBar(content: Text('خطا در ساخت فایل: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اسکن کارت شناسایی'),
        centerTitle: true,
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'لطفاً از پشت و روی کارت خود عکس بگیرید',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                _buildCardPlaceholder('روی کارت', _frontPath, () => _captureImage(true)),
                const SizedBox(height: 20),
                _buildCardPlaceholder('پشت کارت', _backPath, () => _captureImage(false)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_frontPath != null && _backPath != null) ? _generatePdf : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ساخت فایل PDF', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCardPlaceholder(String label, String? path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path != null ? AppColors.primary : Colors.grey[300]!,
            width: 2,
            style: path != null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: path != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}
