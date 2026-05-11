import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/item.dart';
import '../providers/invoice_provider.dart';
import '../database/db_helper.dart';
import '../utils/helpers.dart';
import '../utils/pdf_helper.dart';
import '../utils/share_helper.dart';
import '../widgets/status_badge.dart';
import 'add_invoice_screen.dart';

/// Invoice Detail Screen - Detail dan aksi invoice
class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final data = await DBHelper.instance.getItems(widget.invoice.id!);
    setState(() {
      _items = data.map((map) => Item.fromMap(map)).toList();
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadItems();
  }

  Future<void> _changeStatus(InvoiceStatus newStatus) async {
    await context
        .read<InvoiceProvider>()
        .updateStatus(widget.invoice.id!, newStatus);
    await _refreshData();
  }

  Future<void> _deleteInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Hapus Invoice'),
        content: const Text(
          'Yakin ingin menghapus invoice ini? Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<InvoiceProvider>().deleteInvoice(widget.invoice.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showShareBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bagikan Invoice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  ),
                  title: const Text('WhatsApp'),
                  subtitle: const Text('Kirim ringkasan via WhatsApp'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final invoice = widget.invoice.copyWith(items: _items);
                    ShareHelper.shareToWhatsApp(
                      invoice: invoice,
                      items: _items,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.email, color: Color(0xFFEA4335)),
                  ),
                  title: const Text('Email'),
                  subtitle: const Text('Kirim PDF via email'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final invoice = widget.invoice.copyWith(items: _items);
                    ShareHelper.shareViaEmail(
                      invoice: invoice,
                      items: _items,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? const Color(0xFFE94560)
                              : const Color(0xFF1A1A2E))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: isDark
                          ? const Color(0xFFE94560)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  title: const Text('Share File PDF'),
                  subtitle: const Text('Bagikan file PDF ke aplikasi lain'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final invoice = widget.invoice.copyWith(items: _items);
                    ShareHelper.shareInvoicePdf(
                      invoice: invoice,
                      items: _items,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AddInvoiceScreen(
          editInvoice: widget.invoice.copyWith(items: _items),
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
    if (result == true) {
      await _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Invoice',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () {
              PdfHelper.generateAndPreviewInvoice(
                invoice: widget.invoice,
                items: _items,
              );
            },
          ),

          // Share
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan',
            onPressed: _showShareBottomSheet,
          ),

          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _navigateToEdit,
          ),

          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            tooltip: 'Hapus',
            onPressed: _deleteInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice number & status
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 16),

                  // Customer info
                  _buildCustomerCard(isDark),
                  const SizedBox(height: 16),

                  // Items
                  _buildItemsCard(isDark),
                  const SizedBox(height: 16),

                  // Summary
                  _buildSummaryCard(isDark),
                  const SizedBox(height: 16),

                  // Notes
                  if (widget.invoice.notes.isNotEmpty) _buildNotesCard(isDark),
                  const SizedBox(height: 16),

                  // Status action
                  _buildStatusAction(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    final daysLeft = Helpers.daysUntilDue(widget.invoice.dueDate);
    String? dueInfo;
    Color? dueColor;

    if (widget.invoice.status != InvoiceStatus.paid) {
      if (daysLeft < 0) {
        dueInfo = 'Terlambat ${-daysLeft} hari';
        dueColor = Colors.red;
      } else if (daysLeft == 0) {
        dueInfo = 'Jatuh tempo hari ini';
        dueColor = Colors.orange;
      } else if (daysLeft <= 7) {
        dueInfo = '$daysLeft hari lagi';
        dueColor = Colors.orange;
      } else {
        dueInfo = '$daysLeft hari lagi';
        dueColor = null;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.invoice.invoiceNumber,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF8888AA)
                      : const Color(0xFF9999AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
              StatusBadge(status: widget.invoice.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color:
                    isDark ? const Color(0xFF6666AA) : const Color(0xFFBBBBCC),
              ),
              const SizedBox(width: 4),
              Text(
                Helpers.formatDateFull(widget.invoice.date),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF6666AA)
                      : const Color(0xFFBBBBCC),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.schedule_outlined,
                size: 14,
                color: dueColor ??
                    (isDark
                        ? const Color(0xFF6666AA)
                        : const Color(0xFFBBBBCC)),
              ),
              const SizedBox(width: 4),
              Text(
                'JT: ${Helpers.formatDateFull(widget.invoice.dueDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: dueColor ??
                      (isDark
                          ? const Color(0xFF6666AA)
                          : const Color(0xFFBBBBCC)),
                ),
              ),
            ],
          ),
          if (dueInfo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (dueColor ?? Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: dueColor),
                  const SizedBox(width: 4),
                  Text(
                    dueInfo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFF0F0F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8888AA) : const Color(0xFF9999AA),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isDark
                    ? const Color(0xFFE94560).withValues(alpha: 0.2)
                    : const Color(0xFF1A1A2E).withValues(alpha: 0.1),
                child: Text(
                  widget.invoice.customerName.isNotEmpty
                      ? widget.invoice.customerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE94560)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invoice.customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (widget.invoice.customerEmail.isNotEmpty)
                      Text(
                        widget.invoice.customerEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8888AA)
                              : const Color(0xFF9999AA),
                        ),
                      ),
                    if (widget.invoice.customerPhone.isNotEmpty)
                      Text(
                        widget.invoice.customerPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8888AA)
                              : const Color(0xFF9999AA),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFF0F0F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF8888AA)
                      : const Color(0xFF9999AA),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_items.length} item',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF8888AA)
                      : const Color(0xFF9999AA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8888AA)
                              : const Color(0xFF9999AA),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Text(
                        '${item.qty} x ${Helpers.formatCurrency(item.price)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8888AA)
                              : const Color(0xFF9999AA),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Text(
                          Helpers.formatCurrency(item.total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _items.length - 1) const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * (widget.invoice.tax / 100);
    final discount = widget.invoice.discount;
    final total = subtotal + tax - discount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16162A)]
              : [const Color(0xFF1A1A2E), const Color(0xFF2D2D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            'Subtotal',
            Helpers.formatCurrency(subtotal),
            Colors.white.withValues(alpha: 0.7),
          ),
          if (widget.invoice.tax > 0)
            _buildSummaryRow(
              'Pajak (${widget.invoice.tax.toStringAsFixed(0)}%)',
              Helpers.formatCurrency(tax),
              Colors.white.withValues(alpha: 0.7),
            ),
          if (widget.invoice.discount > 0)
            _buildSummaryRow(
              'Diskon',
              '-${Helpers.formatCurrency(discount)}',
              Colors.red.shade300,
            ),
          const Divider(color: Color(0xFF3A3A5A), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                Helpers.formatCurrency(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color)),
          Text(value, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildNotesCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFFFE082),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes,
                size: 16,
                color:
                    isDark ? const Color(0xFF8888AA) : const Color(0xFFF57F17),
              ),
              const SizedBox(width: 6),
              Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF8888AA)
                      : const Color(0xFFF57F17),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.invoice.notes,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFBBBBCC) : const Color(0xFF5D4037),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(bool isDark) {
    if (widget.invoice.status == InvoiceStatus.paid) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: () => _changeStatus(InvoiceStatus.unpaid),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
            ),
          ),
          child: Text(
            'Tandai Belum Bayar',
            style: TextStyle(
              color: isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => _changeStatus(InvoiceStatus.paid),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, size: 20),
            SizedBox(width: 8),
            Text(
              'Tandai Sudah Dibayar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
