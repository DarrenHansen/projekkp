import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/status_filter_chips.dart';
import '../widgets/empty_state_widget.dart';
import 'add_invoice_screen.dart';

/// Invoice List Screen - Halaman utama daftar invoice
class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Load data saat pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<InvoiceProvider>().searchInvoices(query);
    if (query.isNotEmpty && !_isSearching) {
      setState(() => _isSearching = true);
    } else if (query.isEmpty && _isSearching) {
      setState(() => _isSearching = false);
    }
  }

  void _onSearchClose() {
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<InvoiceProvider>().resetFilters();
  }

  InvoiceStatus? _statusFromString(String filter) {
    switch (filter) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'unpaid':
        return InvoiceStatus.unpaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      default:
        return null;
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    final provider = context.read<InvoiceProvider>();
    if (filter == 'all') {
      provider.filterByStatus(null);
    } else {
      provider.filterByStatus(
        _statusFromString(filter),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark),

            const SizedBox(height: 8),

            // Search bar (tampil saat searching)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClose: _onSearchClose,
                  showClose: true,
                ),
              ),

            if (_isSearching) const SizedBox(height: 12),

            // Status filter chips
            StatusFilterChips(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
            ),

            const SizedBox(height: 12),

            // Invoice list
            Expanded(
              child: Consumer<InvoiceProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingIndicator(context);
                  }

                  final invoices = provider.invoices;

                  if (invoices.isEmpty) {
                    if (_isSearching || _selectedFilter != 'all') {
                      return const EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak Ditemukan',
                        subtitle: 'Coba ubah kata kunci atau filter pencarian.',
                      );
                    }
                    return EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum Ada Invoice',
                      subtitle: 'Buat invoice pertama Anda untuk memulai.',
                      actionIcon: Icons.add,
                      actionLabel: 'Buat Invoice',
                      onAction: () => _navigateToAdd(context),
                    );
                  }

                  return RefreshIndicator(
                    color: isDark
                        ? const Color(0xFFE94560)
                        : const Color(0xFF1A1A2E),
                    onRefresh: () => provider.loadInvoices(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        // Load items untuk setiap invoice
                        return FutureBuilder(
                          future: provider.loadItems(invoices[index].id!),
                          builder: (context, itemSnapshot) {
                            final invoice = invoices[index].copyWith(
                              items: itemSnapshot.data ?? [],
                            );
                            return InvoiceCard(
                              invoice: invoice,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/invoice-detail',
                                  arguments: invoice,
                                ).then((_) => provider.loadInvoices());
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Buat Invoice',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                Consumer<InvoiceProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      '${provider.totalCount} invoice total',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF8888AA)
                            : const Color(0xFF888899),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Search toggle
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search_rounded,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                size: 22,
              ),
              onPressed: () {
                if (_isSearching) {
                  _onSearchClose();
                } else {
                  setState(() => _isSearching = true);
                  // Focus search field
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    () {
                      // Auto-focus search
                    },
                  );
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // Settings / Dark mode toggle
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode_outlined,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                size: 20,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    final provider = context.read<InvoiceProvider>();
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddInvoiceScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
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
    // Refresh list setelah kembali
    if (mounted) {
      provider.loadInvoices();
    }
  }
}
