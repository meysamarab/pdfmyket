import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';

class SubscriptionDialog extends StatefulWidget {
  const SubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
  }

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.purchasePremium();
    if (mounted) {
      setState(() => _isLoading = false);
      if (appState.isPremium) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خرید با موفقیت انجام شد! تمام امکانات فعال شدند.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'خرید نسخه کامل',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'استفاده رایگان شما از این بخش به پایان رسیده است.\nبرای دسترسی نامحدود به تمام امکانات، نسخه کامل را خریداری کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            _buildFeatureRow(Icons.check_circle_outline, 'حذف واترمارک از تمامی فایل‌ها'),
            _buildFeatureRow(Icons.check_circle_outline, 'ادغام نامحدود فایل‌های PDF'),
            _buildFeatureRow(Icons.check_circle_outline, 'تنظیم و فشرده‌سازی بی‌نهایت اسناد'),
            _buildFeatureRow(Icons.check_circle_outline, 'پرداخت یکبار، استفاده برای همیشه'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'خرید نسخه کامل (یکبار خرید)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('فعلاً نه', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
