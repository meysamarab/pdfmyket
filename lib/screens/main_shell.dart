import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_state.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';
import 'camera/multi_capture_screen.dart';
import 'editor/reorder_pages_screen.dart';
import 'files/files_screen.dart';


class MainShell extends StatelessWidget {
  const MainShell({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    FilesScreen(), // User requested Files page here
    HistoryScreen(), // History tab
    SettingsScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final int currentIndex = appState.currentTabIndex;

    return Scaffold(
      body: _screens[currentIndex],
      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final List<String>? result = await Navigator.push<List<String>>(
              context,
              MaterialPageRoute(builder: (context) => const MultiCaptureScreen()),
            );
            if (result != null && result.isNotEmpty && context.mounted) {
              appState.addImages(result);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReorderPagesScreen()),
              );
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 70,
        color: Theme.of(context).cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(child: _buildNavItem(context, icon: Icons.home_rounded, label: 'خانه', index: 0, currentIndex: currentIndex)),
            Expanded(child: _buildNavItem(context, icon: Icons.description_outlined, label: 'فایل‌ها', index: 1, currentIndex: currentIndex)),
            const SizedBox(width: 80), // Space for FAB
            Expanded(child: _buildNavItem(context, icon: Icons.history_rounded, label: 'تاریخچه', index: 2, currentIndex: currentIndex)),
            Expanded(child: _buildNavItem(context, icon: Icons.settings_outlined, label: 'تنظیمات', index: 3, currentIndex: currentIndex)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, required int currentIndex}) {
    final bool isSelected = index == currentIndex;
    return InkWell(
      onTap: () => Provider.of<AppState>(context, listen: false).setTabIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
