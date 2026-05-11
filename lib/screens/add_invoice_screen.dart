import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/item.dart';
import '../providers/invoice_provider.dart';
import '../database/db_helper.dart';
import '../utils/helpers.dart';

/// Add / Edit Invoice Screen
class AddInvoiceScreen extends StatefulWidget {
  final Invoice? editInvoice;

  const AddInvoiceScreen({super.key, this.editInvoice});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Item> _items = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  InvoiceStatus _selectedStatus = InvoiceStatus.unpaid;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editInvoice != null) {
      _isEditing = true;
      final invoice = widget.editInvoice!;
      _customerController.text = invoice.customerName;
      _emailController.text = invoice.customerEmail;
      _phoneController.text = invoice.customerPhone;
      _taxController.text = invoice.tax.toStringAsFixed(0);
      _discountController.text = invoice.discount.toStringAsFixed(0);
      _notesController.text = invoice.notes;
      _selectedDate = DateTime.tryParse(invoice.date) ?? DateTime.now();
      _selectedDueDate = DateTime.tryParse(invoice.dueDate) ??
          DateTime.now().add(const Duration(days: 30));
      _selectedStatus = invoice.status;

      // Load items untuk edit
      _loadItemsForEdit(invoice.id!);
    }
  }

  Future<void> _loadItemsForEdit(int invoiceId) async {
    final data = await DBHelper.instance.getItems(invoiceId);
    setState(() {
      _items = data.map((map) => Item.fromMap(map)).toList();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  double get _taxAmount {
    final tax = double.tryParse(_taxController.text) ?? 0;
    return _subtotal * (tax / 100);
  }

  double get _grandTotal {
    final discount = double.tryParse(_discountController.text) ?? 0;
    return _subtotal + _taxAmount - discount;
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final initial = isDueDate ? _selectedDueDate : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _selectedDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Tambah Item',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      qtyController.text.isNotEmpty) {
                    setState(() {
                      _items.add(Item(
                        invoiceId: 0,
                        productName: nameController.text.trim(),
                        price: double.parse(priceController.text),
                        qty: int.parse(qtyController.text),
                      ));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal 1 item')),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        final invoice = Invoice(
          id: widget.editInvoice?.id,
          invoiceNumber: widget.editInvoice?.invoiceNumber ?? '',
          customerName: _customerController.text.trim(),
          customerEmail: _emailController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          date: Helpers.dateToDb(_selectedDate),
          dueDate: Helpers.dateToDb(_selectedDueDate),
          tax: double.tryParse(_taxController.text) ?? 0,
          discount: double.tryParse(_discountController.text) ?? 0,
          notes: _notesController.text.trim(),
          status: _selectedStatus,
          items: _items,
        );

        final provider = context.read<InvoiceProvider>();
        bool success;

        if (_isEditing) {
          success = await provider.updateInvoice(invoice);
        } else {
          final result = await provider.addInvoice(invoice);
          success = result != null;
        }

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menyimpan invoice')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Invoice' : 'Buat Invoice',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Info Customer
              _buildSectionHeader('Info Customer', isDark),
              const SizedBox(height: 12),

              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Nama Customer *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Tanggal & Status
              _buildSectionHeader('Tanggal & Status', isDark),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Tanggal',
                      date: _selectedDate,
                      isDark: isDark,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Jatuh Tempo',
                      date: _selectedDueDate,
                      isDark: isDark,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isEditing)
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  items: InvoiceStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
              const SizedBox(height: 20),

              // Section: Items
              _buildSectionHeader('Item Produk', isDark),
              const SizedBox(height: 12),

              // List items
              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF5F5FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: isDark
                            ? const Color(0xFF6666AA)
                            : const Color(0xFFCCCCDD),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada item',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF6666AA)
                              : const Color(0xFFCCCCDD),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  return _buildItemTile(item, index, isDark);
                }),

              const SizedBox(height: 12),

              // Tombol tambah item
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Item'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A4A)
                          : const Color(0xFFE0E0F0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Pajak & Diskon
              _buildSectionHeader('Pajak & Diskon', isDark),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pajak (%)',
                        prefixIcon: Icon(Icons.percent),
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Diskon',
                        prefixIcon: Icon(Icons.discount),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Summary
              _buildSummaryCard(isDark),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveInvoice,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Invoice' : 'Simpan Invoice',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          Helpers.formatDate(Helpers.dateToDb(date)),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(Item item, int index, bool isDark) {
    return Dismissible(
      key: ValueKey(item.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.red.shade400),
      ),
      onDismissed: (_) => _removeItem(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.qty} x ${Helpers.formatCurrency(item.price)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF8888AA)
                          : const Color(0xFF9999AA),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Helpers.formatCurrency(item.total),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Subtotal', Helpers.formatCurrency(_subtotal), isDark),
          if (double.tryParse(_taxController.text)?.toInt() != null &&
              (double.tryParse(_taxController.text) ?? 0) > 0)
            _buildSummaryRow(
              'Pajak',
              Helpers.formatCurrency(_taxAmount),
              isDark,
            ),
          if (double.tryParse(_discountController.text)?.toInt() != null &&
              (double.tryParse(_discountController.text) ?? 0) > 0)
            _buildSummaryRow(
              'Diskon',
              '-${Helpers.formatCurrency(double.tryParse(_discountController.text) ?? 0)}',
              isDark,
              textColor: Colors.red,
            ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Grand Total',
            Helpers.formatCurrency(_grandTotal),
            isDark,
            isBold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    double fontSize = 14,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: isDark ? const Color(0xFF8888AA) : const Color(0xFF888899),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor ??
                  (isDark ? Colors.white : const Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }
}
