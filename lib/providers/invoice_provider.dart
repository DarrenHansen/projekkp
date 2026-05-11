import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/invoice.dart';
import '../models/item.dart';

/// Invoice Provider - State Management untuk Invoice
/// Menggunakan ChangeNotifier pattern (Provider)
class InvoiceProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;

  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  InvoiceStatus? _filterStatus;
  String _searchQuery = '';
  bool _isLoading = false;

  List<Invoice> get invoices =>
      _filteredInvoices.isEmpty && _filterStatus == null && _searchQuery.isEmpty
          ? _invoices
          : _filteredInvoices;

  bool get isLoading => _isLoading;
  InvoiceStatus? get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  /// Load semua invoice dari database
  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getInvoices();
      _invoices = data.map((map) {
        final invoice = Invoice.fromMap(map);
        return invoice;
      }).toList();

      // Cek overdue status
      _checkOverdueStatuses();

      // Terapkan filter/search aktif
      await applyFilters();
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cek dan update invoice yang sudah overdue
  void _checkOverdueStatuses() {
    bool changed = false;
    for (var invoice in _invoices) {
      if (invoice.isOverdue && invoice.status != InvoiceStatus.overdue) {
        _dbHelper.updateInvoiceStatus(invoice.id!, 'overdue');
        invoice = invoice.copyWith(status: InvoiceStatus.overdue);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Load items untuk invoice tertentu
  Future<List<Item>> loadItems(int invoiceId) async {
    final data = await _dbHelper.getItems(invoiceId);
    return data.map((map) => Item.fromMap(map)).toList();
  }

  /// Tambah invoice baru
  Future<Invoice?> addInvoice(Invoice invoice) async {
    try {
      // Generate nomor invoice otomatis
      final invoiceNumber = await _dbHelper.generateInvoiceNumber();
      final invoiceWithNumber = invoice.copyWith(invoiceNumber: invoiceNumber);

      final id = await _dbHelper.insertInvoice(invoiceWithNumber.toMap());

      if (id > 0) {
        // Insert items
        final items = invoice.items.map((item) {
          return item.copyWith(invoiceId: id).toMap();
        }).toList();

        if (items.isNotEmpty) {
          await _dbHelper.insertItems(items);
        }

        await loadInvoices();
        return invoiceWithNumber.copyWith(id: id);
      }
    } catch (e) {
      debugPrint('Error adding invoice: $e');
    }
    return null;
  }

  /// Update invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      final result = await _dbHelper.updateInvoice(
        invoice.id!,
        invoice.toMap(),
      );
      if (result > 0) {
        // Hapus items lama, insert yang baru
        await _dbHelper.deleteItemsByInvoiceId(invoice.id!);
        if (invoice.items.isNotEmpty) {
          final items = invoice.items.map((item) {
            return item.copyWith(invoiceId: invoice.id!).toMap();
          }).toList();
          await _dbHelper.insertItems(items);
        }
        await loadInvoices();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating invoice: $e');
    }
    return false;
  }

  /// Hapus invoice
  Future<bool> deleteInvoice(int id) async {
    try {
      final result = await _dbHelper.deleteInvoice(id);
      if (result > 0) {
        await loadInvoices();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
    }
    return false;
  }

  /// Update status invoice
  Future<bool> updateStatus(int id, InvoiceStatus status) async {
    try {
      final result = await _dbHelper.updateInvoiceStatus(id, status.dbValue);
      if (result > 0) {
        await loadInvoices();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
    return false;
  }

  /// Pencarian invoice
  Future<void> searchInvoices(String query) async {
    _searchQuery = query.trim();
    notifyListeners();
    await applyFilters();
  }

  /// Filter berdasarkan status
  Future<void> filterByStatus(InvoiceStatus? status) async {
    _filterStatus = status;
    notifyListeners();
    await applyFilters();
  }

  /// Terapkan filter & search secara bersamaan
  Future<void> applyFilters() async {
    if (_searchQuery.isEmpty && _filterStatus == null) {
      _filteredInvoices = [];
      notifyListeners();
      return;
    }

    if (_searchQuery.isNotEmpty && _filterStatus != null) {
      // Search + Filter
      final searchData = await _dbHelper.searchInvoices(_searchQuery);
      _filteredInvoices = searchData
          .map((map) => Invoice.fromMap(map))
          .where((inv) => inv.status == _filterStatus)
          .toList();
    } else if (_searchQuery.isNotEmpty) {
      // Search only
      final searchData = await _dbHelper.searchInvoices(_searchQuery);
      _filteredInvoices =
          searchData.map((map) => Invoice.fromMap(map)).toList();
    } else if (_filterStatus != null) {
      // Filter only
      final filterData =
          await _dbHelper.filterInvoicesByStatus(_filterStatus!.dbValue);
      _filteredInvoices =
          filterData.map((map) => Invoice.fromMap(map)).toList();
    }

    notifyListeners();
  }

  /// Reset filter & search
  void resetFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filteredInvoices = [];
    notifyListeners();
  }

  /// Ambil statistik
  Future<Map<String, dynamic>> getStats() async {
    return await _dbHelper.getInvoiceStats();
  }

  /// Hitung jumlah per status
  int get totalCount => _invoices.length;
  int get paidCount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.paid).length;
  int get unpaidCount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.unpaid).length;
  int get overdueCount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.overdue).length;

  /// Hitung total revenue dari paid invoices
  double get totalRevenue {
    return _invoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .fold(0, (sum, inv) => sum + inv.total);
  }
}
