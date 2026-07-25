// lib/features/order_history/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/order_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/skeleton_loader.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(
        title: 'My Orders',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const EmptyState(
                title: 'No orders yet',
                subtitle: 'Start browsing our menu and place your first order!',
                icon: Icons.receipt_long_outlined,
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(myOrdersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _OrderTile(order: orders[i]),
                ),
              ),
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemCount: 5,
          itemBuilder: (_, __) => const ListTileSkeleton(),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  Color get _statusColor => switch (order.status) {
        OrderStatus.placed => AppColors.statusPlaced,
        OrderStatus.confirmed => AppColors.statusConfirmed,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.ready => AppColors.statusReady,
        OrderStatus.completed => AppColors.statusCompleted,
        OrderStatus.cancelled => AppColors.statusCancelled,
      };

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(order.placedAt.toLocal());
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.shortId,
                      style: AppTextStyles.labelMd.copyWith(
                          fontFamily: 'Sora', color: const Color(0xFF1B2A4A))),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: AppTextStyles.labelXs.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.formatCompact(order.total),
                    style: AppTextStyles.price.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(order.status.displayName,
                      style: AppTextStyles.labelXs.copyWith(color: _statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (order.status) {
        OrderStatus.placed => Icons.access_time_rounded,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.preparing => Icons.restaurant_rounded,
        OrderStatus.ready => Icons.done_all_rounded,
        OrderStatus.completed => Icons.check_circle_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };
}
