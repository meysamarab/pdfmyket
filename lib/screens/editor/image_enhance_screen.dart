import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_utils;
import '../../core/app_colors.dart';

class ImageProcessorArgs {
  final String imagePath;
  final double brightness; // -1 to 1
  final double contrast;   // 0 to 2
  final bool isBW;

  ImageProcessorArgs(this.imagePath, this.brightness, this.contrast, this.isBW);
}

Future<String> processImageInIsolate(ImageProcessorArgs args) async {
  final bytes = File(args.imagePath).readAsBytesSync();
  var decodedImage = img.decodeImage(bytes);
  if (decodedImage == null) throw Exception("Could not decode image");

  if (args.brightness != 0 || args.contrast != 1.0 || args.isBW) {
     final c = args.contrast;
     final t = (1.0 - c) * 255 / 2.0;
     final b = args.brightness * 255;
     
     for (var p in decodedImage) {
        num r = p.r;
        num g = p.g;
        num bl = p.b;

        if (args.isBW) {
           final luma = 0.33 * r + 0.33 * g + 0.33 * bl;
           r = luma;
           g = luma;
           bl = luma;
        }

        // Apply contrast
        r = r * c + t;
        g = g * c + t;
        bl = bl * c + t;
        
        // Apply brightness
        r += b;
        g += b;
        bl += b;
        
        p.r = r.clamp(0, 255).toInt();
        p.g = g.clamp(0, 255).toInt();
        p.b = bl.clamp(0, 255).toInt();
     }
  }

  final newBytes = img.encodeJpg(decodedImage, quality: 90);
  final originalFile = File(args.imagePath);
  final dir = originalFile.parent;
  final name = path_utils.basenameWithoutExtension(originalFile.path);
  final newPath = '${dir.path}/${name}_enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  await File(newPath).writeAsBytes(newBytes);
  return newPath;
}

class ImageEnhanceScreen extends StatefulWidget {
  final String imagePath;
  final Function(String newPath) onSaved;

  const ImageEnhanceScreen({super.key, required this.imagePath, required this.onSaved});

  @override
  State<ImageEnhanceScreen> createState() => _ImageEnhanceScreenState();
}

class _ImageEnhanceScreenState extends State<ImageEnhanceScreen> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _isBW = false;
  bool _isProcessing = false;

  void _applyMagic() {
    setState(() {
      _brightness = 0.15;
      _contrast = 1.6;
      _isBW = false;
    });
  }

  void _applyMagicBW() {
    setState(() {
      _brightness = 0.2;
      _contrast = 1.8;
      _isBW = true;
    });
  }

  void _reset() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _isBW = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isProcessing = true);
    try {
      final args = ImageProcessorArgs(
        widget.imagePath,
        _brightness,
        _contrast,
        _isBW,
      );
      final newPath = await compute(processImageInIsolate, args);
      widget.onSaved(newPath);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در پردازش تصویر: $e', style: const TextStyle(fontFamily: 'IRANSans'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _contrast;
    final t = (1.0 - c) * 255 / 2;
    final List<double> contrastMatrix = [
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ];

    final b = _brightness * 255;
    final List<double> brightnessMatrix = [
      1.0, 0.0, 0.0, 0.0, b,
      0.0, 1.0, 0.0, 0.0, b,
      0.0, 0.0, 1.0, 0.0, b,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    final List<double> bwMatrix = [
      0.33, 0.33, 0.33, 0.0, 0.0,
      0.33, 0.33, 0.33, 0.0, 0.0,
      0.33, 0.33, 0.33, 0.0, 0.0,
      0.0,  0.0,  0.0,  1.0, 0.0,
    ];

    Widget image = Image.file(File(widget.imagePath), fit: BoxFit.contain);
    
    if (_isBW) {
      image = ColorFiltered(colorFilter: ColorFilter.matrix(bwMatrix), child: image);
    }
    image = ColorFiltered(colorFilter: ColorFilter.matrix(contrastMatrix), child: image);
    image = ColorFiltered(colorFilter: ColorFilter.matrix(brightnessMatrix), child: image);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('ویرایش و بهبود', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          if (_isProcessing)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
          else
            TextButton(
              onPressed: _save,
              child: const Text('ذخیره', style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: image),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton('اصلی', Icons.replay, _reset),
                    _buildPresetButton('رنگی+', Icons.auto_fix_high, _applyMagic),
                    _buildPresetButton('سیاه سفید+', Icons.document_scanner, _applyMagicBW),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSliderRow(
                  'روشنایی', 
                  Icons.light_mode, 
                  _brightness, 
                  -1.0, 1.0, 
                  (v) => setState(() => _brightness = v),
                ),
                const SizedBox(height: 12),
                _buildSliderRow(
                  'کنتراست', 
                  Icons.contrast, 
                  _contrast, 
                  0.0, 2.0, 
                  (v) => setState(() => _contrast = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, IconData icon, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.outlineVariant,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
