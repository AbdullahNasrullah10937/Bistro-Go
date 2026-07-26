// lib/features/admin/admin_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/order_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../shared_widgets/empty_error_states.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF292524)),
          onPressed: () => context.pop(),
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
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Number & Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.shortId,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1917),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on ${DateFormat('MMM dd, yyyy').format(order.placedAt)} at ${DateFormat('h:mm a').format(order.placedAt)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 16),

              // Print Ticket Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printing kitchen ticket...')),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFFB83806)),
                  label: const Text(
                    'Print Ticket',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB83806),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFB83806)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Card 1: Order Items ─────────────────────────────────────────
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.receipt_long_rounded, color: Color(0xFFB83806), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Order Items',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Food photo thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFF5F5F4),
                                  child: const Icon(Icons.restaurant, color: Color(0xFFA8A29E), size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1917),
                                      ),
                                    ),
                                    if (item.selectedAddons.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Add-ons: ${item.selectedAddons.length} selected',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF78716C),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Price & Quantity
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatCompact(item.unitPrice),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: Color(0xFF44403C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 1, color: Color(0xFFF5F5F4)),
                    const SizedBox(height: 12),

                    // Subtotal, Tax, Delivery Fee
                    _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.formatCompact(order.subtotal)),
                    const SizedBox(height: 6),
                    _SummaryRow(label: 'Tax (8.5%)', value: CurrencyFormatter.formatCompact(order.tax)),
                    const SizedBox(height: 6),
                    _SummaryRow(label: 'Delivery Fee', value: CurrencyFormatter.formatCompact(order.deliveryFee)),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF5F5F4)),
                    const SizedBox(height: 12),

                    // Total Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCompact(order.total),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Card 2: Customer Notes (Yellow Highlight Card) ──────────────
              if (order.notes?.isNotEmpty == true) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF78350F), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Customer Notes',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${order.notes}"',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Card 3: Update Status ────────────────────────────────────────
              if (!order.status.isTerminal) ...[
                _CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Status',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary status action
                      _StatusActionButton(
                        orderId: orderId,
                        status: _nextStatus(order.status),
                        ref: ref,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 10),

                      // Secondary status action if applicable
                      if (order.status == OrderStatus.confirmed)
                        _StatusActionButton(
                          orderId: orderId,
                          status: OrderStatus.preparing,
                          ref: ref,
                          isPrimary: false,
                        ),

                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel Order'),
                                content: const Text('Are you sure you want to cancel this order?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('No')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Cancel Order',
                                          style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(orderServiceProvider)
                                  .updateOrderStatus(orderId, OrderStatus.cancelled);
                              ref.invalidate(orderDetailProvider(orderId));
                            }
                          },
                          child: const Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF78716C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Card 4: Customer Details ────────────────────────────────────
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_outline_rounded, color: Color(0xFFB83806), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Customer Details',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF64748B),
                          child: Text(
                            order.customerName?.isNotEmpty == true
                                ? order.customerName!.substring(0, 2).toUpperCase()
                                : 'CU',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName ?? 'Eleanor James',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1917),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: const [
                                Icon(Icons.phone_outlined, size: 14, color: Color(0xFF78716C)),
                                SizedBox(width: 4),
                                Text(
                                  '(555) 123-4567',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF78716C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'DELIVERY ADDRESS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA8A29E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress ??
                          (order.isDineIn ? 'Dine-In · Table ${order.tableNumber}' : '1284 Sycamore Lane, Apt 4B, Portland, OR 97204'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF44403C),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map snippet placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        color: const Color(0xFFE2E8F0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.map_outlined, size: 48, color: Color(0xFF94A3B8)),
                            Positioned(
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Map View',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFB83806)),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
      ),
    );
  }

  OrderStatus _nextStatus(OrderStatus current) {
    return switch (current) {
      OrderStatus.placed => OrderStatus.confirmed,
      OrderStatus.confirmed => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.completed,
      _ => OrderStatus.completed,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      OrderStatus.placed => (const Color(0xFFE0F2FE), const Color(0xFF0369A1), Icons.receipt_outlined),
      OrderStatus.confirmed => (const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.check_circle_outline),
      OrderStatus.preparing => (const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.inventory_2_outlined),
      OrderStatus.ready => (const Color(0xFFDCFCE7), const Color(0xFF15803D), Icons.done_all),
      OrderStatus.completed => (const Color(0xFFDCFCE7), const Color(0xFF15803D), Icons.task_alt),
      OrderStatus.cancelled => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), Icons.cancel_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends ConsumerStatefulWidget {
  final String orderId;
  final OrderStatus status;
  final WidgetRef ref;
  final bool isPrimary;

  const _StatusActionButton({
    required this.orderId,
    required this.status,
    required this.ref,
    required this.isPrimary,
  });

  @override
  ConsumerState<_StatusActionButton> createState() => _StatusActionButtonState();
}

class _StatusActionButtonState extends ConsumerState<_StatusActionButton> {
  bool _loading = false;

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

  @override
  Widget build(BuildContext context) {
    final label = 'Mark as ${widget.status.displayName}';

    if (widget.isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _update,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB83806),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _update,
        icon: const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFFB83806)),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB83806),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFB83806)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF78716C),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1917),
          ),
        ),
      ],
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }
}
