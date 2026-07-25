// lib/features/item_detail/item_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/item_addon.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/primary_button.dart';
import '../../shared_widgets/skeleton_loader.dart';


class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  int _quantity = 1;
  final Set<String> _selectedAddons = {};
  String? _notes;
  bool _addingToCart = false;

  double _addonsTotal(List<ItemAddon> addons) {
    return _selectedAddons.fold(0.0, (sum, id) {
      final a = addons.where((a) => a.id == id).firstOrNull;
      return sum + (a?.extraPrice ?? 0);
    });
  }

  Future<void> _addToCart(String menuItemId) async {
    setState(() => _addingToCart = true);
    try {
      await ref.read(cartNotifierProvider.notifier).addItem(
            menuItemId: menuItemId,
            quantity: _quantity,
            selectedAddonIds: _selectedAddons.toList(),
            notes: _notes,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)),
        );
        _safePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  void _safePop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(menuItemDetailProvider(widget.itemId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      body: itemAsync.when(
        data: (item) {
          final basePrice = item.price;
          final totalPrice = (basePrice + _addonsTotal(item.addons)) * _quantity;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Hero image ────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: const Color(0xFFF4F1EC),
                    leading: GestureDetector(
                      onTap: _safePop,

                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.onSurface),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const SkeletonBox(width: double.infinity, height: double.infinity),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceContainer,
                                child: const Icon(Icons.restaurant_menu,
                                    size: 64, color: AppColors.outline),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceContainer,
                              child: const Icon(Icons.restaurant_menu,
                                  size: 64, color: AppColors.outline),
                            ),
                    ),
                  ),

                  // ── Details ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tags
                          if (item.tags.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children: item.tags
                                  .map((t) => _TagPill(t))
                                  .toList(),
                            ),
                          const SizedBox(height: 12),

                          // Name + Price row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(item.name,
                                    style: AppTextStyles.headlineMd.copyWith(
                                        fontFamily: 'Sora',
                                        color: const Color(0xFF1B2A4A))),
                              ),
                              Text(
                                CurrencyFormatter.formatCompact(basePrice),
                                style: AppTextStyles.priceLg,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(item.description,
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 24),

                          // ── Quantity stepper ─────────────────────────────
                          Row(
                            children: [
                              Text('Quantity',
                                  style: AppTextStyles.labelMd.copyWith(
                                      color: const Color(0xFF1B2A4A))),
                              const Spacer(),
                              _QuantityStepper(
                                quantity: _quantity,
                                onDecrease: () =>
                                    setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                                onIncrease: () =>
                                    setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
                              ),
                            ],
                          ),

                          // ── Add-ons ───────────────────────────────────────
                          if (item.addons.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('Customise',
                                style: AppTextStyles.labelMd.copyWith(
                                    color: const Color(0xFF1B2A4A))),
                            const SizedBox(height: 12),
                            ...item.addons.map((addon) => _AddonTile(
                                  addon: addon,
                                  selected: _selectedAddons.contains(addon.id),
                                  onToggle: (v) {
                                    setState(() {
                                      if (v) {
                                        _selectedAddons.add(addon.id);
                                      } else {
                                        _selectedAddons.remove(addon.id);
                                      }
                                    });
                                  },
                                )),
                          ],

                          // ── Special notes ─────────────────────────────────
                          const SizedBox(height: 24),
                          Text('Special Instructions',
                              style: AppTextStyles.labelMd.copyWith(
                                  color: const Color(0xFF1B2A4A))),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (v) => _notes = v.isEmpty ? null : v,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'E.g. no onions, extra sauce...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0x331B2A4A)),
                              ),
                            ),
                          ),

                          // Extra space for bottom bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Add to Cart Bar ──────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: AppColors.outlineVariant, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total',
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                          Text(
                            CurrencyFormatter.formatCompact(totalPrice),
                            style: AppTextStyles.priceLg,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Add to Cart',
                          onPressed: () => _addToCart(item.id),
                          isLoading: _addingToCart,
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(menuItemDetailProvider(widget.itemId))),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill(this.tag);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(tag,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper(
      {required this.quantity, required this.onDecrease, required this.onIncrease});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove, onTap: onDecrease, enabled: quantity > 1),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
            key: ValueKey(quantity),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$quantity', style: AppTextStyles.headlineSm),
          ),
        ),
        _StepBtn(icon: Icons.add, onTap: onIncrease, enabled: true),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: enabled ? Colors.white : AppColors.outline),
      ),
    );
  }
}

class _AddonTile extends StatelessWidget {
  final ItemAddon addon;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _AddonTile(
      {required this.addon, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outline, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(addon.name, style: AppTextStyles.bodyMd),
            ),
            Text(
              '+${CurrencyFormatter.formatCompact(addon.extraPrice)}',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
