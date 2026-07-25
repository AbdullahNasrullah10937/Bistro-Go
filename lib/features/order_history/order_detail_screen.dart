// lib/features/order_history/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/order_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/primary_button.dart';
import '../../shared_widgets/status_stepper.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: const BistroAppBar(title: 'Order Details'),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.shortId, style: AppTextStyles.headlineSm.copyWith(fontFamily: 'Sora', color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(DateFormat('MMM d, yyyy · h:mm a').format(order.placedAt.toLocal()),
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(order.status.displayName, style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Status stepper (compact)
              _Card(title: 'Status', child: StatusStepper(currentStatus: order.status, compact: true)),
              const SizedBox(height: AppSpacing.md),

              // Items
              _Card(
                title: 'Items',
                child: Column(children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text('${item.quantity}× ${item.itemName}', style: AppTextStyles.bodyMd)),
                    Text(CurrencyFormatter.formatCompact(item.lineTotal), style: AppTextStyles.labelMd),
                  ]),
                )).toList()),
              ),
              const SizedBox(height: AppSpacing.md),

              // Total
              _Card(
                title: 'Payment Summary',
                child: Column(children: [
                  _Row('Subtotal', order.subtotal),
                  _Row('Tax', order.tax),
                  _Row('Delivery', order.deliveryFee),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: AppTextStyles.headlineSm),
                    Text(CurrencyFormatter.formatCompact(order.total), style: AppTextStyles.priceLg),
                  ]),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Reorder
              PrimaryButton(
                label: 'Track Order',
                onPressed: () => context.push('/order-tracking/${order.id}'),
                icon: Icons.gps_fixed_rounded,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: e.toString()),
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
        boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        Text(CurrencyFormatter.formatCompact(amount), style: AppTextStyles.labelMd),
      ]),
    );
  }
}
