// lib/features/admin/add_edit_menu_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/menu_provider.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/storage_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/primary_button.dart';

class AddEditMenuItemScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const AddEditMenuItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends ConsumerState<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _categoryId;
  bool _isAvailable = true;
  List<String> _tags = [];
  File? _imageFile;
  String? _existingImageUrl;
  bool _loading = false;
  bool _uploading = false;


  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) _loadItem();
  }

  Future<void> _loadItem() async {
    final item = await ref.read(menuServiceProvider).fetchItemById(widget.itemId!);
    setState(() {
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description;
      _priceCtrl.text = item.price.toStringAsFixed(2);
      _categoryId = item.categoryId;
      _isAvailable = item.isAvailable;
      _tags = List.from(item.tags);
      _existingImageUrl = item.imageUrl;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String? imageUrl = _existingImageUrl;

      // Upload new image if selected
      if (_imageFile != null) {
        setState(() => _uploading = true);
        imageUrl = await ref.read(storageServiceProvider).uploadMenuImage(_imageFile!);
        if (!mounted) return;
        setState(() => _uploading = false);
      }


      final data = {
        'category_id': _categoryId,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'image_url': imageUrl,
        'is_available': _isAvailable,
        'tags': _tags,
      };

      if (widget.itemId != null) {
        await ref.read(menuServiceProvider).updateItem(widget.itemId!, data);
      } else {
        await ref.read(menuServiceProvider).createItem(data);
      }

      ref.invalidate(adminMenuItemsProvider);
      ref.invalidate(menuItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.itemId != null ? 'Item updated!' : 'Item created!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; _uploading = false; });
    }
  }

  static const _availableTags = ['Vegan', 'Vegetarian', 'Gluten-Free', 'Spicy', 'Best Seller', 'New'];

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemId != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(title: isEdit ? 'Edit Item' : 'Add Item'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.3), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _existingImageUrl != null
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    size: 40, color: AppColors.outline),
                                const SizedBox(height: 8),
                                Text('Tap to upload image',
                                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline)),
                              ],
                            ),
                ),
              ),
              if (_uploading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(color: AppColors.primary),
              ],
              const SizedBox(height: AppSpacing.md),

              // ── Name ───────────────────────────────────────────────────────
              _buildField('Item Name', _nameCtrl, 'e.g. Avocado Toast',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
              const SizedBox(height: AppSpacing.md),

              // ── Description ────────────────────────────────────────────────
              _buildField('Description', _descCtrl, 'Describe the dish...',
                  maxLines: 3),
              const SizedBox(height: AppSpacing.md),

              // ── Price ──────────────────────────────────────────────────────
              _buildField('Price (\$)', _priceCtrl, '0.00',
                  type: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Price is required';
                    if (double.tryParse(v) == null) return 'Enter a valid price';
                    return null;
                  }),
              const SizedBox(height: AppSpacing.md),

              // ── Category ───────────────────────────────────────────────────
              Text('Category', style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
              const SizedBox(height: 6),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  value: _categoryId,
                  hint: const Text('Select category'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x331B2A4A))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const LinearProgressIndicator(color: AppColors.primary),
                error: (_, __) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Tags ───────────────────────────────────────────────────────
              Text('Tags', style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final selected = _tags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) _tags.remove(tag);
                        else _tags.add(tag);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryFixed : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: selected ? AppColors.primary : AppColors.outlineVariant,
                            width: 1.5),
                      ),
                      child: Text(tag,
                          style: AppTextStyles.labelSm.copyWith(
                              color: selected ? AppColors.primary : AppColors.onSurface)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Available toggle ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                ),
                child: Row(
                  children: [
                    Text('Available for ordering', style: AppTextStyles.bodyMd),
                    const Spacer(),
                    Switch(
                      value: _isAvailable,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isAvailable = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: isEdit ? 'Update Item' : 'Add to Menu',
                onPressed: _save,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x331B2A4A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x331B2A4A))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
