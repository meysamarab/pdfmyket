import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/app_colors.dart';

class MultiCaptureScreen extends StatefulWidget {
  const MultiCaptureScreen({super.key});

  @override
  State<MultiCaptureScreen> createState() => _MultiCaptureScreenState();
}

class _MultiCaptureScreenState extends State<MultiCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _capturedPaths = [];
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    // Auto-start first capture
    WidgetsBinding.instance.addPostFrameCallback((_) => _capturePhoto());
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() {
          _capturedPaths.add(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _cropImage(int index) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _capturedPaths[index],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'برش تصویر',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'برش تصویر',
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() {
        _capturedPaths[index] = croppedFile.path;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedPaths.removeAt(index);
    });
  }

  void _confirmAndReturn() {
    Navigator.pop(context, _capturedPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.pop(context, <String>[]),
        ),
        title: Text(
          'عکس‌برداری (${_capturedPaths.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
      body: Column(
        children: [
          // Preview area
          Expanded(
            child: _capturedPaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 80, color: AppColors.outline.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'دوربین در حال باز شدن...',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _capturedPaths.length,
                    itemBuilder: (context, index) {
                      return _buildImageCard(index);
                    },
                  ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Take more photos button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isCapturing ? null : _capturePhoto,
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: const Text('عکس بعدی'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _capturedPaths.isEmpty ? null : _confirmAndReturn,
                    icon: const Icon(Icons.check, size: 20),
                    label: Text('تایید (${_capturedPaths.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.file(
            File(_capturedPaths[index]),
            fit: BoxFit.cover,
          ),
          // Page number badge
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'صفحه ${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // Action buttons
          Positioned(
            top: 6,
            right: 6,
            child: Column(
              children: [
                _buildSmallAction(Icons.crop, () => _cropImage(index)),
                const SizedBox(height: 4),
                _buildSmallAction(Icons.delete, () => _removeImage(index), isError: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAction(IconData icon, VoidCallback onTap, {bool isError = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isError ? AppColors.error : AppColors.primary).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
