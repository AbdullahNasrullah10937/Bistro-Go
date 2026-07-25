// lib/features/admin/admin_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/order_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/status_stepper.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

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
              _Card(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.shortId, style: AppTextStyles.headlineSm.copyWith(fontFamily: 'Sora', color: AppColors.primary)),
                          if (order.customerName != null) ...[
                            const SizedBox(height: 2),
                            Text(order.customerName!, style: AppTextStyles.bodyMd),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            order.isDineIn ? 'Dine-In · Table ${order.tableNumber}' : 'Delivery Order',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.formatCompact(order.total), style: AppTextStyles.priceLg),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Status stepper
              _Card(
                title: 'Status',
                child: StatusStepper(currentStatus: order.status),
              ),
              const SizedBox(height: AppSpacing.md),

              // Items
              _Card(
                title: 'Items (${order.items.length})',
                child: Column(
                  children: order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item.quantity}× ${item.itemName}', style: AppTextStyles.bodyMd)),
                        Text(CurrencyFormatter.formatCompact(item.lineTotal), style: AppTextStyles.labelMd),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (order.notes?.isNotEmpty == true)
                _Card(
                  title: 'Customer Notes',
                  child: Text(order.notes!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              if (order.notes?.isNotEmpty == true) const SizedBox(height: AppSpacing.md),

              // Advance status
              if (!order.status.isTerminal) ...[
                _Card(
                  title: 'Update Status',
                  child: Column(
                    children: _nextStatuses(order.status).map((status) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StatusActionButton(
                        orderId: orderId,
                        status: status,
                        ref: ref,
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
      ),
    );
  }

  List<OrderStatus> _nextStatuses(OrderStatus current) {
    return OrderStatus.values.where((s) => current.canTransitionTo(s)).toList();
  }
}

class _StatusActionButton extends ConsumerStatefulWidget {
  final String orderId;
  final OrderStatus status;
  final WidgetRef ref;
  const _StatusActionButton({required this.orderId, required this.status, required this.ref});

  @override
  ConsumerState<_StatusActionButton> createState() => _StatusActionButtonState();
}

class _StatusActionButtonState extends ConsumerState<_StatusActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isCancelAction = widget.status == OrderStatus.cancelled;
    return SizedBox(
      width: double.infinity,
      child: isCancelAction
          ? OutlinedButton(
              onPressed: _loading ? null : _update,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                  : Text('Cancel Order', style: AppTextStyles.labelMd.copyWith(color: AppColors.error)),
            )
          : ElevatedButton(
              onPressed: _loading ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Mark as ${widget.status.displayName}', style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
            ),
    );
  }

  Future<void> _update() async {
    setState(() => _loading = true);
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(widget.orderId, widget.status);
      ref.invalidate(orderDetailProvider(widget.orderId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;
  const _Card({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
