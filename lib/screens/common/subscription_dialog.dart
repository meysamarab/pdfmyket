import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';

class SubscriptionDialog extends StatelessWidget {
  const SubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SubscriptionDialog(),
    );
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
              'خرید اشتراک سالانه',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'استفاده رایگان شما به پایان رسیده است. برای ادامه استفاده از تمامی امکانات برنامه، لطفا اشتراک سالانه تهیه کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(Icons.check_circle_outline, 'حذف واترمارک از تمامی فایل‌ها'),
            _buildFeatureRow(Icons.check_circle_outline, 'ادغام نامحدود فایل‌های PDF'),
            _buildFeatureRow(Icons.check_circle_outline, 'تنظیم و فشرده‌سازی بی‌نهایت اسناد'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.subscribe();
                if (context.mounted && appState.isSubscribed) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اشتراک شما با موفقیت فعال شد!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('خرید اشتراک سالانه (۱ ساله)', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
