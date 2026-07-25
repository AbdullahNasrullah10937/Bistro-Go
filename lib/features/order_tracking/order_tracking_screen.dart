// lib/features/order_tracking/order_tracking_screen.dart
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
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/primary_button.dart';
import '../../shared_widgets/status_stepper.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _channel = Supabase.instance.client
        .channel('order-${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.ordersTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            if (mounted && payload.newRecord.isNotEmpty) {
              ref.invalidate(orderDetailProvider(widget.orderId));
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
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: const BistroAppBar(title: 'Order Tracking'),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order ID ────────────────────────────────────────────────
              _HeaderCard(order: order),
              const SizedBox(height: AppSpacing.md),

              // ── Status Stepper ───────────────────────────────────────────
              _Card(
                title: 'Order Status',
                child: StatusStepper(currentStatus: order.status),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Realtime indicator ───────────────────────────────────────
              if (!order.status.isTerminal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live updates enabled',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // ── Order Items ──────────────────────────────────────────────
              _Card(
                title: 'Items',
                child: Column(
                  children: order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}× ${item.itemName}',
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCompact(item.lineTotal),
                          style: AppTextStyles.labelMd,
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Totals ───────────────────────────────────────────────────
              _Card(
                title: 'Payment',
                child: Column(
                  children: [
                    _Row('Subtotal', order.subtotal),
                    _Row('Tax', order.tax),
                    _Row('Delivery', order.deliveryFee),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppTextStyles.headlineSm),
                        Text(CurrencyFormatter.formatCompact(order.total),
                            style: AppTextStyles.priceLg),
                      ],
                    ),
                  ],
                ),
              ),

              if (order.status == OrderStatus.completed) ...[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Back to Menu',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Order order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shortId,
                    style: AppTextStyles.headlineSm.copyWith(
                        fontFamily: 'Sora', color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(
                  order.isDineIn
                      ? 'Table ${order.tableNumber}'
                      : 'Delivery Order',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _StatusBadge(order.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge(this.status);

  Color get _color => switch (status) {
        OrderStatus.placed => AppColors.statusPlaced,
        OrderStatus.confirmed => AppColors.statusConfirmed,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.ready => AppColors.statusReady,
        OrderStatus.completed => AppColors.statusCompleted,
        OrderStatus.cancelled => AppColors.statusCancelled,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.labelSm.copyWith(color: _color),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  const _Row(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          Text(CurrencyFormatter.formatCompact(amount), style: AppTextStyles.labelMd),
        ],
      ),
    );
  }
}
