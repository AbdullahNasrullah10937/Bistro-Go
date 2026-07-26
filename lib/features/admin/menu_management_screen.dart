// lib/features/admin/menu_management_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/skeleton_loader.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(adminMenuItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF2ECE4),
            child: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF44403C)),
          ),
        ),
        title: const Text(
          'Bistro Go',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB83806),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Search section
          Container(
            color: const Color(0xFFF9F7F2),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Management',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1917),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your restaurant offerings.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 16),

                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1917)),
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFFA8A29E),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF78716C), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB83806), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items Table Card
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                final filtered = _searchQuery.isEmpty
                    ? allItems
                    : allItems.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No menu items',
                    subtitle: _searchQuery.isEmpty
                        ? 'Add your first item using the + button.'
                        : 'No items match "$_searchQuery"',
                    icon: Icons.restaurant_menu_rounded,
                    actionLabel: 'Add Item',
                    onAction: () => context.push(AppRoutes.addMenuItem),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFFB83806),
                  onRefresh: () async => ref.invalidate(adminMenuItemsProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A3E37).withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF5F5F4)),
                      ),
                      child: Column(
                        children: [
                          // Table Header Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'Item',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF44403C),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Price',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF44403C),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Status',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF44403C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF5F5F4)),

                          // Table Item Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F4)),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _MenuItemRow(
                                item: item,
                                onEdit: () => context.push('/admin/menu/edit/${item.id}'),
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Item'),
                                      content: Text('Delete "${item.name}"? This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(menuServiceProvider).deleteItem(item.id);
                                    ref.invalidate(adminMenuItemsProvider);
                                  }
                                },
                                onToggleAvailability: () async {
                                  await ref.read(menuServiceProvider).toggleAvailability(
                                        item.id,
                                        !item.isAvailable,
                                      );
                                  ref.invalidate(adminMenuItemsProvider);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(20),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: 5,
                itemBuilder: (_, __) => const ListTileSkeleton(),
              ),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminMenuItemsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addMenuItem),
        backgroundColor: const Color(0xFFB83806),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7E5E4))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dash Tab
              InkWell(
                onTap: () => context.go(AppRoutes.adminDashboard),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.grid_view_rounded, color: Color(0xFF78716C), size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Dash',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Menu Tab (Filled Terracotta Pill)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB83806),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Menu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Tab
              InkWell(
                onTap: () => context.push(AppRoutes.adminSettings),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.settings_outlined, color: Color(0xFF78716C), size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _MenuItemRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Thumbnail + Title
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFF5F5F4),
                            child: const Icon(Icons.restaurant, color: Color(0xFFA8A29E), size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isAvailable ? const Color(0xFF1C1917) : const Color(0xFFA8A29E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCompact(item.price),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1917),
                ),
              ),
            ),

            // Status Switch
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Switch(
                  value: item.isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFB83806),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE7E5E4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
