// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/menu_item_card.dart';
import '../../shared_widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final itemsAsync = ref.watch(menuItemsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(categoriesProvider);
                ref.invalidate(menuItemsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding, 20,
                          AppSpacing.screenPadding, 0),
                      child: _Header(profileAsync: profileAsync),
                    ),
                  ),

                  // ── Search bar ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding, 20,
                          AppSpacing.screenPadding, 0),
                      child: _SearchBar(
                        controller: _searchCtrl,
                        onChanged: (q) {
                          ref.read(searchQueryProvider.notifier).state = q;
                          setState(() => _isSearching = q.trim().isNotEmpty);
                        },
                        onClear: () {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() => _isSearching = false);
                        },
                      ),
                    ),
                  ),

                  if (_isSearching) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding, 20, AppSpacing.screenPadding, 8),
                        child: Text('Search Results',
                            style: AppTextStyles.headlineSm),
                      ),
                    ),
                    _SearchResultsSliver(),
                  ] else ...[
                    // ── Category chips ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: categoriesAsync.when(
                          data: (cats) => ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemCount: cats.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return _CategoryChip(
                                  label: 'All',
                                  selected: selectedCategory == null,
                                  onTap: () => ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state = null,
                                );
                              }
                              final cat = cats[i - 1];
                              return _CategoryChip(
                                label: cat.name,
                                selected: selectedCategory == cat.id,
                                onTap: () => ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = cat.id,
                              );
                            },
                          ),
                          loading: () => const _CategoryChipsSkeleton(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // ── Section title ──────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding, 24,
                          AppSpacing.screenPadding, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          selectedCategory == null
                              ? 'Our Menu'
                              : categoriesAsync.when(
                                  data: (cats) => cats
                                          .where((c) => c.id == selectedCategory)
                                          .firstOrNull
                                          ?.name ??
                                      'Menu',
                                  loading: () => 'Menu',
                                  error: (_, __) => 'Menu',
                                ),
                          style: AppTextStyles.headlineMd,
                        ),
                      ),
                    ),

                    // ── Menu grid ──────────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding, 16,
                          AppSpacing.screenPadding, 100),
                      sliver: itemsAsync.when(
                        data: (items) => items.isEmpty
                            ? SliverToBoxAdapter(
                                child: EmptyState(
                                  title: 'No items available',
                                  subtitle: 'Check back later for more dishes.',
                                  icon: Icons.restaurant_menu_rounded,
                                ),
                              )
                            : SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.gutter,
                                  mainAxisSpacing: AppSpacing.gutter,
                                  childAspectRatio: 0.65,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => MenuItemCard(
                                    item: items[i],
                                    onTap: () => context.push(
                                        '/item/${items[i].id}'),
                                  ),
                                  childCount: items.length,
                                ),
                              ),
                        loading: () => const SliverToBoxAdapter(
                            child: MenuGridSkeleton()),
                        error: (e, _) => SliverToBoxAdapter(
                          child: ErrorState(
                            message: e.toString(),
                            onRetry: () => ref.invalidate(menuItemsProvider),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Sticky Cart Bar ───────────────────────────────────────────
            if (cartCount > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _StickyCartBar(
                  count: cartCount,
                  subtotal: cartSubtotal,
                  onTap: () => context.push(AppRoutes.cart),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AsyncValue profileAsync;
  const _Header({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    final name = profileAsync.when(
      data: (p) => p?.name?.split(' ').first ?? 'there',
      loading: () => '...',
      error: (_, __) => 'there',
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good day, $name 👋',
                  style: AppTextStyles.headlineMd.copyWith(
                      fontFamily: 'Sora', color: const Color(0xFF1B2A4A))),
              const SizedBox(height: 2),
              Text('What are you craving today?',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        // Cart icon button
        Consumer(builder: (_, ref, __) {
          final count = ref.watch(cartCountProvider);
          return GestureDetector(
            onTap: () => context.push(AppRoutes.cart),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF1B2A4A).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 22, color: AppColors.onSurface),
                ),
                if (count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: 'Search dishes, drinks...',
          hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.35)),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 22, color: AppColors.outline),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.outline),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? Colors.white : AppColors.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsSkeleton extends StatelessWidget {
  const _CategoryChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonBox(width: 80, height: 38,
          borderRadius: BorderRadius.all(Radius.circular(100))),
    );
  }
}

class _SearchResultsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 100),
      sliver: results.when(
        data: (items) => items.isEmpty
            ? SliverToBoxAdapter(
                child: EmptyState(
                  title: 'No results found',
                  subtitle: 'Try a different search term.',
                  icon: Icons.search_off_rounded,
                ),
              )
            : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.gutter,
                  mainAxisSpacing: AppSpacing.gutter,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => MenuItemCard(
                    item: items[i],
                    onTap: () => context.push('/item/${items[i].id}'),
                  ),
                  childCount: items.length,
                ),
              ),
        loading: () => const SliverToBoxAdapter(child: MenuGridSkeleton()),
        error: (e, _) => SliverToBoxAdapter(
          child: ErrorState(message: e.toString()),
        ),
      ),
    );
  }
}

class _StickyCartBar extends StatefulWidget {
  final int count;
  final double subtotal;
  final VoidCallback onTap;

  const _StickyCartBar({required this.count, required this.subtotal, required this.onTap});

  @override
  State<_StickyCartBar> createState() => _StickyCartBarState();
}

class _StickyCartBarState extends State<_StickyCartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${widget.count}',
                  style: AppTextStyles.labelMd.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('View Cart',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              Text(
                CurrencyFormatter.formatCompact(widget.subtotal),
                style: AppTextStyles.labelMd.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
