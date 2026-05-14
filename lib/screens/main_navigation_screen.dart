import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_localizations.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/business_profile_provider.dart';
import 'invoice_list_screen.dart';
import 'items_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';
import 'add_invoice_screen.dart';

/// Main Navigation Screen - Bottom navigation with Items, Clients, Settings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InvoiceListScreen(),
    const ItemsScreen(),
    const ClientsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
      context.read<CustomerProvider>().loadCustomers();
      context.read<ProductProvider>().loadProducts();
      context.read<BusinessProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AddInvoiceScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
            ),
          );
          if (mounted) {
            context.read<InvoiceProvider>().loadInvoices();
          }
        },
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          loc.get('create_invoice'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D1A) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFEEEEF0), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.receipt_long_outlined, loc.get('invoices'), 0, isDark),
                _buildNavItem(Icons.inventory_2_outlined, loc.get('items_products'), 1, isDark),
                _buildNavItem(Icons.people_outline, loc.get('clients_contacts'), 2, isDark),
                _buildNavItem(Icons.settings_outlined, loc.get('settings'), 3, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? (isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E))
        : (isDark ? const Color(0xFF6666AA) : const Color(0xFF9999AA));

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
