// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF292524), size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF78716C), size: 22),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.adminLogin);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          Container(
            color: const Color(0xFFF9F7F2),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
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
                  'Kitchen & Live Orders Overview',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                ordersAsync.when(
                  data: (orders) => _StatsRow(orders: orders),
                  loading: () => const SizedBox(height: 76),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Status filter chips
          _StatusFilterBar(
            selected: statusFilter,
            onSelected: (s) => ref.read(adminStatusFilterProvider.notifier).state = s,
          ),
          const SizedBox(height: 8),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFB83806),
              onRefresh: () async => ref.invalidate(adminOrdersProvider(statusFilter)),
              child: ordersAsync.when(
                data: (orders) => orders.isEmpty
                    ? const EmptyState(
                        title: 'No orders found',
                        subtitle: 'No incoming orders match this status filter.',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => _AdminOrderTile(order: orders[i]),
                      ),
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(20),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ListTileSkeleton(),
                ),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(adminOrdersProvider(statusFilter)),
                ),
              ),
            ),
          ),
        ],
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
              // Active Dash Tab (Filled Terracotta Pill)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB83806),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Dash',
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

              // Menu Tab
              InkWell(
                onTap: () => context.push(AppRoutes.menuManagement),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.restaurant_rounded, color: Color(0xFF78716C), size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Menu',
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

              // Settings Tab
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings feature coming soon.')),
                  );
                },
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

class _StatsRow extends StatelessWidget {
  final List<Order> orders;
  const _StatsRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => !o.status.isTerminal).length;
    final todayRevenue = orders
        .where((o) => o.status == OrderStatus.completed && o.placedAt.day == DateTime.now().day)
        .fold(0.0, (sum, o) => sum + o.total);

    return Row(
      children: [
        _StatCard(label: 'Active', value: '$active', icon: Icons.fastfood_rounded),
        const SizedBox(width: 8),
        _StatCard(
            label: 'Revenue',
            value: CurrencyFormatter.formatCompact(todayRevenue),
            icon: Icons.payments_outlined),
        const SizedBox(width: 8),
        _StatCard(
            label: 'Today', value: '${orders.length}', icon: Icons.receipt_long_outlined),
      ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E5E4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3E37).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFB83806), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1917),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF78716C),
              ),
            ),
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
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _filters.entries.map((e) {
          final isSelected = selected == e.value;
          return GestureDetector(
            onTap: () => onSelected(e.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFB83806) : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? const Color(0xFFB83806) : const Color(0xFFE7E5E4),
                ),
              ),
              child: Center(
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF44403C),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AdminOrderTile extends ConsumerWidget {
  final Order order;
  const _AdminOrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusBg, statusFg) = _statusColors(order.status);
    return InkWell(
      onTap: () => context.push('/admin/orders/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5F5F4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3E37).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon Box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon(order.status), color: statusFg, size: 20),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.shortId,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (order.isDineIn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Table ${order.tableNumber}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName ?? 'Customer',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF78716C),
                    ),
                  ),
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFA8A29E),
                    ),
                  ),
                ],
              ),
            ),

            // Price & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatCompact(order.total),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColors(OrderStatus s) => switch (s) {
        OrderStatus.placed => (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
        OrderStatus.confirmed => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
        OrderStatus.preparing => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
        OrderStatus.ready => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
        OrderStatus.completed => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
        OrderStatus.cancelled => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
        _ => (const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
      };

  IconData _statusIcon(OrderStatus s) => switch (s) {
        OrderStatus.placed => Icons.access_time_rounded,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.preparing => Icons.inventory_2_outlined,
        OrderStatus.ready => Icons.done_all_rounded,
        OrderStatus.completed => Icons.check_circle_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
        _ => Icons.info_outline,
      };
}
