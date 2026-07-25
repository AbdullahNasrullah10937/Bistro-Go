// lib/features/admin/menu_management_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/skeleton_loader.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminMenuItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(
        title: 'Menu Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.addMenuItem),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) => items.isEmpty
            ? EmptyState(
                title: 'No menu items',
                subtitle: 'Add your first item using the + button.',
                icon: Icons.restaurant_menu_rounded,
                actionLabel: 'Add Item',
                onAction: () => context.push(AppRoutes.addMenuItem),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(adminMenuItemsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _MenuItemAdminTile(
                    item: items[i],
                    onEdit: () => context.push('/admin/menu/edit/${items[i].id}'),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: Text('Delete "${items[i].name}"? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(menuServiceProvider).deleteItem(items[i].id);
                        ref.invalidate(adminMenuItemsProvider);
                      }
                    },
                    onToggleAvailability: () async {
                      await ref.read(menuServiceProvider).toggleAvailability(
                            items[i].id, !items[i].isAvailable);
                      ref.invalidate(adminMenuItemsProvider);
                    },
                  ),
                ),
              ),
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemCount: 6,
          itemBuilder: (_, __) => const ListTileSkeleton(),
        ),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(adminMenuItemsProvider)),
      ),
    );
  }
}

class _MenuItemAdminTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _MenuItemAdminTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !item.isAvailable ? Border.all(color: AppColors.outline.withValues(alpha: 0.3)) : null,
        boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null
                ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64, height: 64,
                    color: AppColors.surfaceContainer,
                    child: const Icon(Icons.restaurant_menu, color: AppColors.outline),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: AppTextStyles.labelMd.copyWith(
                          color: item.isAvailable ? AppColors.onSurface : AppColors.outline)),
                    ),
                    if (!item.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('Unavailable',
                            style: AppTextStyles.labelXs.copyWith(color: AppColors.error)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.formatCompact(item.price), style: AppTextStyles.price.copyWith(fontSize: 14)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.outline),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'toggle') onToggleAvailability();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'toggle',
                  child: Text(item.isAvailable ? 'Mark Unavailable' : 'Mark Available')),
              const PopupMenuItem(value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }
}
