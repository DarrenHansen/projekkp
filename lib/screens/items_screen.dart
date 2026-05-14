import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/helpers.dart';
import '../utils/app_localizations.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/empty_state_widget.dart';

/// Items/Products Screen - Kelola data barang/produk
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredProducts = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await context.read<ProductProvider>().searchProducts(query);
    setState(() => _filteredProducts = results);
  }

  void _showAddProductDialog({Product? editProduct}) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: editProduct?.name ?? '');
    final descController = TextEditingController(text: editProduct?.description ?? '');
    final priceController = TextEditingController(text: editProduct?.price.toStringAsFixed(0) ?? '');
    String photoPath = editProduct?.photoPath ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(loc.get(editProduct != null ? 'edit_product' : 'add_product'), style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (picked != null) {
                          setDialogState(() => photoPath = picked.path);
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16162A) : const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE0E0F0)),
                        ),
                        child: photoPath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(photoPath), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 30, color: isDark ? const Color(0xFF6666AA) : const Color(0xFF9999AA)),
                                  const SizedBox(height: 4),
                                  Text(loc.get('product_photo'), style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF6666AA) : const Color(0xFF9999AA))),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: loc.get('product_name'), prefixIcon: const Icon(Icons.inventory_2_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(labelText: loc.get('notes'), prefixIcon: const Icon(Icons.notes)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: loc.get('price'), prefixIcon: const Icon(Icons.attach_money)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.get('cancel'))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                  final product = Product(
                    id: editProduct?.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    price: double.parse(priceController.text),
                    photoPath: photoPath,
                  );
                  if (editProduct != null) {
                    await context.read<ProductProvider>().updateProduct(product);
                  } else {
                    await context.read<ProductProvider>().addProduct(product);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(loc.get('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteProduct(Product product) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.get('delete_product')),
        content: Text(loc.get('delete_product_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.get('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<ProductProvider>().deleteProduct(product.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(loc.get('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.get('items_products'),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A2E), letterSpacing: -0.5),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: isDark ? Colors.white : const Color(0xFF1A1A2E), size: 22),
                      onPressed: () {
                        if (_isSearching) {
                          _searchController.clear();
                          setState(() { _isSearching = false; _filteredProducts = []; });
                        } else {
                          setState(() => _isSearching = true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AppSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClose: () { _searchController.clear(); setState(() { _isSearching = false; _filteredProducts = []; }); },
                  hintText: loc.get('search_products'),
                ),
              ),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final products = _isSearching ? _filteredProducts : provider.products;

                  if (products.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: loc.get('no_products'),
                      subtitle: loc.get('create_first_product'),
                      actionIcon: Icons.add,
                      actionLabel: loc.get('add_product'),
                      onAction: () => _showAddProductDialog(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFF0F0F5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF16162A) : const Color(0xFFF5F5FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: product.photoPath.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(product.photoPath), fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.inventory_2_outlined, size: 24),
                          ),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(Helpers.formatCurrency(product.price), style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showAddProductDialog(editProduct: product)),
                              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400), onPressed: () => _deleteProduct(product)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
