import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/file_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'تنظیمات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Theme.of(context).cardColor,
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
            const Text(
              'تنظیمات برنامه',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'تنظیمات عمومی و اطلاعات برنامه',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // General section
            _buildSectionTitle('عمومی'),
            const SizedBox(height: 8),
            _buildSettingsCard(context, [
              _SettingsItem(
                icon: appState.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                title: 'حالت شب',
                subtitle: appState.themeMode == ThemeMode.dark ? 'فعال' : 'غیرفعال',
                trailing: Switch(
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    appState.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: AppColors.primary,
                ),
                onTap: () {
                  appState.setThemeMode(
                    appState.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark
                  );
                },
              ),
            ]),

            // Storage section
            _buildSectionTitle('حافظه'),
            const SizedBox(height: 8),
            _buildSettingsCard(context, [
              _SettingsItem(
                icon: Icons.cleaning_services,
                title: 'پاک‌سازی کش',
                subtitle: 'حذف فایل‌های موقت',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('پاک‌سازی کش'),
                      content: const Text('آیا مطمئن هستید؟ این عمل فقط فایل‌های موقت را حذف می‌کند.'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('انصراف'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('کش پاک‌سازی شد')),
                            );
                          },
                          child: const Text('پاک‌سازی'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // About section
            _buildSectionTitle('درباره'),
            const SizedBox(height: 8),
            _buildSettingsCard(context, [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'نسخه برنامه',
                subtitle: '1.0.2',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.description,
                title: 'مجوزها',
                subtitle: 'مجوزهای متن‌باز',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'CCScaner',
                    applicationVersion: '1.0.2',
                  );
                },
              ),
            ]),

            const SizedBox(height: 40),

            // App branding
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CCScaner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ابزار ساده تبدیل تصویر و پی‌دی‌اف',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<_SettingsItem> items) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: item.trailing ?? (item.onTap != null
                    ? const Icon(Icons.chevron_left, color: AppColors.outline, size: 20)
                    : null),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 72,
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
