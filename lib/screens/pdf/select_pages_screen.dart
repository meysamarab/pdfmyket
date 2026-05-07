import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../core/app_colors.dart';
import '../../services/pdf_service.dart';
import '../../services/app_state.dart';
import '../../models/file_item.dart';
import '../common/processing_screen.dart';
import '../common/subscription_dialog.dart';
import '../result/result_screen.dart';

class SelectPagesScreen extends StatefulWidget {
  final String pdfPath;
  const SelectPagesScreen({super.key, required this.pdfPath});

  @override
  State<SelectPagesScreen> createState() => _SelectPagesScreenState();
}

class _SelectPagesScreenState extends State<SelectPagesScreen> {
  final Set<int> _selectedIndices = {};
  List<Uint8List>? _pageImages;
  bool _isLoading = true;
  PdfExportProfile _selectedProfile = PdfExportProfile.standard;

  @override
  void initState() {
    super.initState();
    _loadPdfPages();
  }

  Future<void> _loadPdfPages() async {
    try {
      final pages = await PdfService.renderPdfPages(widget.pdfPath);
      setState(() {
        _pageImages = pages;
        _isLoading = false;
        // Select all by default
        for (int i = 0; i < pages.length; i++) {
          _selectedIndices.add(i);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری صفحات: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportToImages() async {
    if (_selectedIndices.isEmpty) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    if (_selectedProfile != PdfExportProfile.standard && !appState.canUseFeature('adjust')) {
      SubscriptionDialog.show(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProcessingScreen()),
    );

    try {
      final allImages = await PdfService.pdfToImages(widget.pdfPath, profile: _selectedProfile);
      final selectedFiles = _selectedIndices.map((i) => allImages[i]).toList();
      
      // We only need to show the last one in result screen, or a success message
      FileItem? lastItem;
      for (final file in selectedFiles) {
        lastItem = FileItem(
          id: file.path.hashCode.toString(),
          name: p.basename(file.path),
          path: file.path,
          size: await file.length(),
          createdAt: DateTime.now(),
          type: AppFileType.image,
        );
        appState.addRecentFile(lastItem);
      }

      if (mounted && lastItem != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(fileItem: lastItem!)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در تبدیل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'انتخاب صفحات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIndices.length == _pageImages!.length) {
                    _selectedIndices.clear();
                  } else {
                    for (int i = 0; i < _pageImages!.length; i++) {
                      _selectedIndices.add(i);
                    }
                  }
                });
              },
              child: Text(
                _selectedIndices.length == (_pageImages?.length ?? 0) ? 'لغو انتخاب' : 'انتخاب همه',
                style: const TextStyle(color: AppColors.primary),
              ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _pageImages!.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndices.contains(index);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            _selectedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5),
                            width: isSelected ? 2 : 1,
                          ),
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
                            Image.memory(
                              _pageImages![index],
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              Container(
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Center(
                                  child: Icon(Icons.check_circle, color: AppColors.primary, size: 40),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'صفحه ${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Compression profiles
                Positioned(
                  bottom: 100, // Above the footer
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تنظیمات کاهش حجم برای تصاویر خروجی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildMiniProfileOption('استاندارد', PdfExportProfile.standard),
                              const SizedBox(width: 8),
                              _buildMiniProfileOption('دولتی', PdfExportProfile.government, isPremium: true),
                              const SizedBox(width: 8),
                              _buildMiniProfileOption('سفارت', PdfExportProfile.embassy, isPremium: true),
                              const SizedBox(width: 8),
                              _buildMiniProfileOption('حداکثر', PdfExportProfile.maxCompression, isPremium: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
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
                    child: ElevatedButton.icon(
                      onPressed: _selectedIndices.isEmpty ? null : _exportToImages,
                      icon: const Icon(Icons.image_outlined),
                      label: Text('تبدیل صفحات انتخاب شده (${_selectedIndices.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMiniProfileOption(String label, PdfExportProfile profile, {bool isPremium = false}) {
    final isSelected = _selectedProfile == profile;
    return InkWell(
      onTap: () => setState(() => _selectedProfile = profile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            if (isPremium && !isSelected) ...[
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
