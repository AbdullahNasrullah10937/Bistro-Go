// lib/features/cart/cart_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_item.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/primary_button.dart';
import '../../../core/constants/app_constants.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final tax = subtotal * AppConstants.taxRate;
    final delivery = subtotal > 0 ? AppConstants.deliveryFee : 0.0;
    final total = subtotal + tax + delivery;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(
        title: 'Your Cart',
        actions: [
          if (cartAsync.value?.isNotEmpty == true)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Remove all items from your cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true) ref.read(cartNotifierProvider.notifier).clearCart();
              },
              child: Text('Clear', style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: cartAsync.when(
        data: (items) => items.isEmpty
            ? EmptyState(
                title: 'Your cart is empty',
                subtitle: 'Add some delicious items from the menu!',
                icon: Icons.shopping_bag_outlined,
                actionLabel: 'Browse Menu',
                onAction: () => context.go(AppRoutes.home),
              )
            : Column(
                children: [
                  // Items list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _CartItemTile(item: items[i]),
                    ),
                  ),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1)),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow('Subtotal', subtotal),
                        const SizedBox(height: 6),
                        _SummaryRow('Tax (8%)', tax),
                        const SizedBox(height: 6),
                        _SummaryRow('Delivery', delivery),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTextStyles.headlineSm),
                            Text(CurrencyFormatter.formatCompact(total),
                                style: AppTextStyles.priceLg),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Proceed to Checkout',
                          onPressed: () => context.push(AppRoutes.checkout),
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(cartNotifierProvider),
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItem = item.menuItem;
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) =>
          ref.read(cartNotifierProvider.notifier).removeItem(item.id),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: menuItem?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: menuItem!.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppColors.surfaceContainer,
                      child: const Icon(Icons.restaurant_menu,
                          color: AppColors.outline),
                    ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem?.name ?? 'Unknown Item',
                    style: AppTextStyles.labelMd.copyWith(fontFamily: 'Sora'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCompact(item.lineTotal),
                    style: AppTextStyles.price.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quantity controls
            Row(
              children: [
                _QtyBtn(
                  icon: Icons.remove,
                  onTap: () => ref
                      .read(cartNotifierProvider.notifier)
                      .updateQuantity(item.id, item.quantity - 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('${item.quantity}', style: AppTextStyles.headlineSm),
                ),
                _QtyBtn(
                  icon: Icons.add,
                  onTap: () => ref
                      .read(cartNotifierProvider.notifier)
                      .updateQuantity(item.id, item.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurface),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  const _SummaryRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        Text(CurrencyFormatter.formatCompact(amount),
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface)),
      ],
    );
  }
}
