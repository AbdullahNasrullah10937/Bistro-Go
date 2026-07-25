// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/order_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/skeleton_loader.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _channel = Supabase.instance.client
        .channel('admin-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.ordersTable,
          callback: (_) {
            if (mounted) {
              ref.invalidate(adminOrdersProvider(ref.read(adminStatusFilterProvider)));
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusFilter = ref.watch(adminStatusFilterProvider);
    final ordersAsync = ref.watch(adminOrdersProvider(statusFilter));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A4A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.white),
            tooltip: 'Menu Management',
            onPressed: () => context.push(AppRoutes.menuManagement),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.adminLogin);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats summary ────────────────────────────────────────────────
          ordersAsync.when(
            data: (orders) => _StatsBar(orders: orders),
            loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Status filter tabs ───────────────────────────────────────────
          _StatusFilterBar(
            selected: statusFilter,
            onSelected: (s) => ref.read(adminStatusFilterProvider.notifier).state = s,
          ),

          // ── Orders list ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(adminOrdersProvider(statusFilter)),
              child: ordersAsync.when(
                data: (orders) => orders.isEmpty
                    ? const EmptyState(
                        title: 'No orders',
                        subtitle: 'No orders match the selected filter.',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => _AdminOrderCard(order: orders[i]),
                      ),
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ListTileSkeleton(),
                ),
                error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(adminOrdersProvider(statusFilter))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final List<Order> orders;
  const _StatsBar({required this.orders});

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => !o.status.isTerminal).length;
    final todayRevenue = orders
        .where((o) => o.status == OrderStatus.completed && o.placedAt.day == DateTime.now().day)
        .fold(0.0, (sum, o) => sum + o.total);

    return Container(
      color: const Color(0xFF1B2A4A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatCard(label: 'Active Orders', value: '$active', icon: Icons.fastfood_rounded),
          const SizedBox(width: 12),
          _StatCard(label: 'Today\'s Revenue', value: CurrencyFormatter.formatCompact(todayRevenue), icon: Icons.payments_outlined),
          const SizedBox(width: 12),
          _StatCard(label: 'Total Today', value: '${orders.length}', icon: Icons.receipt_long_outlined),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;
  const _StatusFilterBar({required this.selected, required this.onSelected});

  static const _filters = <String, OrderStatus?>{
    'All': null,
    'Placed': OrderStatus.placed,
    'Confirmed': OrderStatus.confirmed,
    'Preparing': OrderStatus.preparing,
    'Ready': OrderStatus.ready,
    'Done': OrderStatus.completed,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _filters.entries.map((e) {
          final isSelected = selected == e.value;
          return GestureDetector(
            onTap: () => onSelected(e.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(e.key,
                    style: AppTextStyles.labelSm.copyWith(
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final Order order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _color(order.status);
    return GestureDetector(
      onTap: () => context.push('/admin/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon(order.status), color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(order.shortId, style: AppTextStyles.labelMd.copyWith(fontFamily: 'Sora')),
                      const SizedBox(width: 6),
                      if (order.isDineIn)
                        _Tag('Table ${order.tableNumber}', AppColors.tertiary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(order.customerName ?? 'Customer',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  Text('${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.formatCompact(order.total), style: AppTextStyles.price.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(order.status.displayName, style: AppTextStyles.labelXs.copyWith(color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _color(OrderStatus s) => switch (s) {
    OrderStatus.placed => AppColors.statusPlaced,
    OrderStatus.confirmed => AppColors.statusConfirmed,
    OrderStatus.preparing => AppColors.statusPreparing,
    OrderStatus.ready => AppColors.statusReady,
    OrderStatus.completed => AppColors.statusCompleted,
    OrderStatus.cancelled => AppColors.statusCancelled,
  };

  IconData _icon(OrderStatus s) => switch (s) {
    OrderStatus.placed => Icons.access_time_rounded,
    OrderStatus.confirmed => Icons.check_circle_outline_rounded,
    OrderStatus.preparing => Icons.restaurant_rounded,
    OrderStatus.ready => Icons.done_all_rounded,
    OrderStatus.completed => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: AppTextStyles.labelXs.copyWith(color: color)),
    );
  }
}
