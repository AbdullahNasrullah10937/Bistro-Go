// lib/features/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_item.dart';
import '../../services/order_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/primary_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _orderType = 'delivery'; // 'delivery' | 'dine_in' | 'takeaway'
  final _tableCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  bool _placing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'label': 'Cash on Delivery / Pickup', 'icon': Icons.payments_outlined},
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card_outlined},
    {'id': 'wallet', 'label': 'Digital Wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  @override
  void dispose() {
    _tableCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItem> cartItems) async {
    if (_orderType == 'delivery' && _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_orderType == 'dine_in' && _tableCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your table number'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final cartPayload = cartItems.map((ci) {
        double addonTotal = 0;
        if (ci.menuItem != null) {
          for (final addonId in ci.selectedAddonIds) {
            final addon = ci.menuItem!.addons
                .where((a) => a.id == addonId)
                .firstOrNull;
            if (addon != null) addonTotal += addon.extraPrice;
          }
        }
        return {
          'menu_item_id': ci.menuItemId,
          'item_name': ci.menuItem?.name ?? 'Menu Item',
          'quantity': ci.quantity,
          'unit_price': ci.menuItem?.price ?? 0.0,
          'addon_total': addonTotal,
          'selected_addons': ci.selectedAddonIds,
          'notes': ci.notes,
        };
      }).toList();

      final order = await ref.read(orderServiceProvider).placeOrder(
            cartItems: cartPayload,
            orderType: _orderType,
            tableNumber: _orderType == 'dine_in' ? _tableCtrl.text.trim() : null,
            addressId: null,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            paymentMethod: _paymentMethod,
          );

      await ref.read(cartNotifierProvider.notifier).clearCart();

      if (!mounted) return;
      context.go('/order-placed/${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final tax = subtotal * AppConstants.taxRate;
    final delivery = _orderType == 'delivery' ? AppConstants.deliveryFee : 0.0;
    final total = subtotal + tax + delivery;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: const BistroAppBar(title: 'Checkout'),
      body: cartAsync.when(
        data: (items) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Type Selector ─────────────────────────────────
                    _SectionCard(
                      title: 'Order Type',
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeToggle(
                              label: 'Delivery',
                              icon: Icons.delivery_dining_rounded,
                              selected: _orderType == 'delivery',
                              onTap: () => setState(() => _orderType = 'delivery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeToggle(
                              label: 'Takeaway',
                              icon: Icons.shopping_bag_outlined,
                              selected: _orderType == 'takeaway',
                              onTap: () => setState(() => _orderType = 'takeaway'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeToggle(
                              label: 'Dine-In',
                              icon: Icons.restaurant_rounded,
                              selected: _orderType == 'dine_in',
                              onTap: () => setState(() => _orderType = 'dine_in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),


                    // ── Delivery / Table / Pickup ──────────────────────────
                    if (_orderType != 'takeaway') ...[
                      _SectionCard(
                        title: _orderType == 'dine_in' ? 'Table Number' : 'Delivery Address',
                        child: TextField(
                          controller: _orderType == 'dine_in' ? _tableCtrl : _addressCtrl,
                          decoration: InputDecoration(
                            hintText: _orderType == 'dine_in'
                                ? 'e.g. Table 7'
                                : 'Enter your full delivery address',
                            prefixIcon: Icon(
                                _orderType == 'dine_in'
                                    ? Icons.table_restaurant_rounded
                                    : Icons.location_on_outlined,
                                size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x331B2A4A))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else ...[
                      _SectionCard(
                        title: 'Pickup Location',
                        child: const Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Bistro Go Main Counter',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],


                    // ── Payment Method ─────────────────────────────────────
                    _SectionCard(
                      title: 'Payment Method',
                      child: Column(
                        children: _paymentMethods
                            .map((pm) => _PaymentTile(
                                  id: pm['id'] as String,
                                  label: pm['label'] as String,
                                  icon: pm['icon'] as IconData,
                                  selected: _paymentMethod == pm['id'],
                                  onTap: () =>
                                      setState(() => _paymentMethod = pm['id'] as String),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Special Notes ──────────────────────────────────────
                    _SectionCard(
                      title: 'Order Notes (optional)',
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any special requests for this order?',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0x331B2A4A))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Order Summary ──────────────────────────────────────
                    _SectionCard(
                      title: 'Order Summary',
                      child: Column(
                        children: [
                          ...items.map((ci) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${ci.quantity}× ${ci.menuItem?.name ?? 'Item'}',
                                        style: AppTextStyles.bodyMd,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatCompact(ci.lineTotal),
                                      style: AppTextStyles.labelMd,
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 16),
                          _Row('Subtotal', subtotal),
                          _Row('Tax (8%)', tax),
                          if (_orderType == 'delivery') _Row('Delivery Fee', delivery),

                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: AppTextStyles.headlineSm),
                              Text(CurrencyFormatter.formatCompact(total),
                                  style: AppTextStyles.priceLg),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Place Order CTA ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              color: Colors.white,
              child: PrimaryButton(
                label: 'Place Order · ${CurrencyFormatter.formatCompact(total)}',
                onPressed: () => _placeOrder(items),
                isLoading: _placing,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle(
      {required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.outline, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String id, label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile(
      {required this.id, required this.label, required this.icon,
       required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryFixed : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMd),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
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
