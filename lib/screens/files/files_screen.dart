import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../models/file_item.dart';
import '../../services/app_state.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _searchQuery = '';
  AppFileType? _typeFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadRecentFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'فایل‌های من',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Theme.of(context).cardColor,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                final filteredFiles = _filterFiles(appState.recentFiles);

                if (appState.recentFiles.isEmpty) {
                  return _buildEmptyState(
                    title: 'هنوز فایلی ساخته نشده',
                    subtitle: 'فایل‌های خروجی شما اینجا نمایش داده می‌شوند',
                  );
                }

                if (filteredFiles.isEmpty) {
                  return _buildEmptyState(
                    title: 'نتیجه‌ای یافت نشد',
                    subtitle: 'جستجوی خود را تغییر دهید',
                    icon: Icons.search_off_rounded,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => appState.loadRecentFiles(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) {
                      return _buildFileCard(context, filteredFiles[index], appState);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'جستجو در فایل‌ها...',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          Row(
            children: [
              _buildFilterChip('همه', null),
              const SizedBox(width: 8),
              _buildFilterChip('پی‌دی‌اف‌ها', AppFileType.pdf),
              const SizedBox(width: 8),
              _buildFilterChip('عکس‌ها', AppFileType.image),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AppFileType? type) {
    final isSelected = _typeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _typeFilter = selected ? type : null);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white.withOpacity(0.05) 
          : AppColors.surfaceContainerLow,
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide(
        color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
      ),
    );
  }

  List<FileItem> _filterFiles(List<FileItem> files) {
    return files.where((file) {
      final matchesSearch = file.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _typeFilter == null || file.type == _typeFilter;
      return matchesSearch && matchesType;
    }).toList();
  }

  Widget _buildEmptyState({required String title, required String subtitle, IconData icon = Icons.description_outlined}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, FileItem file, AppState appState) {
    final isPdf = file.type == AppFileType.pdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPdf 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.red.withOpacity(0.1) : const Color(0xFFFFEBEE)) 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.blue.withOpacity(0.1) : const Color(0xFFE3F2FD)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
            color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${file.sizeString} • ${_formatDate(file.createdAt)}',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.outline),
          onPressed: () => _showActionsSheet(context, file, appState),
        ),
        onTap: () => OpenFilex.open(file.path),
      ),
    );
  }

  void _showActionsSheet(BuildContext context, FileItem file, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
              title: const Text('باز کردن'),
              onTap: () {
                Navigator.pop(context);
                OpenFilex.open(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppColors.primary),
              title: const Text('اشتراک‌گذاری'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(file.path)]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('حذف', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, file, appState);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FileItem file, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فایل'),
        content: Text('آیا از حذف "${file.name}" مطمئن هستید؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              appState.removeRecentFile(file.path);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'امروز';
    if (diff.inDays == 1) return 'دیروز';
    if (diff.inDays < 7) return '${diff.inDays} روز پیش';

    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
