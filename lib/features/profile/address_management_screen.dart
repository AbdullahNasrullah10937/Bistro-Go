// lib/features/profile/address_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/empty_error_states.dart';
import '../../shared_widgets/primary_button.dart';

final _addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.read(addressServiceProvider).fetchAddresses();
});

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(_addressesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(
        title: 'Saved Addresses',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: addressesAsync.when(
        data: (addresses) => addresses.isEmpty
            ? EmptyState(
                title: 'No addresses saved',
                subtitle: 'Add a delivery address for faster checkout.',
                icon: Icons.location_on_outlined,
                actionLabel: 'Add Address',
                onAction: () => _showAddDialog(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemCount: addresses.length,
                itemBuilder: (_, i) => _AddressTile(
                  address: addresses[i],
                  onDelete: () async {
                    await ref.read(addressServiceProvider).deleteAddress(addresses[i].id);
                    ref.invalidate(_addressesProvider);
                  },
                  onSetDefault: () async {
                    await ref.read(addressServiceProvider).setDefault(addresses[i].id);
                    ref.invalidate(_addressesProvider);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(message: e.toString()),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController(text: 'Home');
    final lineCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    bool isDefault = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Address', style: AppTextStyles.headlineSm),
              const SizedBox(height: 16),
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)')),
              const SizedBox(height: 12),
              TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Address Line')),
              const SizedBox(height: 12),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v ?? false),
                title: const Text('Set as default address'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Save Address',
                onPressed: () async {
                  if (lineCtrl.text.trim().isEmpty) return;
                  await ref.read(addressServiceProvider).addAddress(
                        label: labelCtrl.text.trim(),
                        addressLine: lineCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        isDefault: isDefault,
                      );
                  ref.invalidate(_addressesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressTile({
    required this.address,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: address.isDefault
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label, style: AppTextStyles.labelMd),
                    if (address.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('Default', style: AppTextStyles.labelXs.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(address.fullAddress, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.outline),
            onSelected: (v) {
              if (v == 'default') onSetDefault();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (!address.isDefault)
                const PopupMenuItem(value: 'default', child: Text('Set as Default')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }
}
